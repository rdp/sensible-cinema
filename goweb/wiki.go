package main

import ( "fmt"
        "io/ioutil"
        "net/http"
	"html/template"
        "regexp"
        "os"
        "strings"
        "path/filepath"
        "path"
)

type Page struct {
    Title string
    Body  []byte
}

var validPath = regexp.MustCompile("^/(edit|save|view)/([a-zA-Z0-9- ]+)$") // security check

var DirName string = "editable_files"; // will be overwritten, can't assign nil?

func (p *Page) save() error {
    filename := DirName + "/" + p.Title + ".txt"
    // make sure if we encode it and decode it, it has the same number of quotes
    // which would imply that it parses right to our object, at least :P
    prettyBytes, err := CheckEdlString(p.Body)
    if err != nil {
      return err
    } else { 
      return ioutil.WriteFile(filename, prettyBytes, 0600)
    }
}

func loadPage(title string) (*Page, error) {
    filename := DirName + "/" + title + ".txt"
    return loadPageFilename(filename)
}

func loadPageFilename(filename string) (*Page, error) {
    title := strings.TrimSuffix(filepath.Base(filename), filepath.Ext(filename))
    body, err := ioutil.ReadFile(filename)
    if err != nil {
        return nil, err
    }
    return &Page{Title: title, Body: body}, nil
} 

func searchHandler(w http.ResponseWriter, r *http.Request) {
    movieurl := r.URL.Query()["movieurl"][0];
    for _, filename := range AllPaths() {
      body, _:= ioutil.ReadFile(filename)
      var edl Edl
      edl.BytesToEdl(body) // XXX panic errors here
      if movieurl == edl.AmazonURL || movieurl == edl.GooglePlayURL || movieurl == edl.NetflixURL || movieurl == edl.HuluUrl {
        title := strings.TrimSuffix(filepath.Base(filename), filepath.Ext(filename))
        url := "/view/" + title + "?raw=1"
        fmt.Println("found match:" + title + "for " + movieurl)
        fmt.Fprintf(w, "http://%s%s", r.Host, url)
        return
      }
    }
    fmt.Println("not found match for " + movieurl)
    fmt.Fprintf(w, "not found not yet in database %s!", movieurl)
    http.NotFound(w, r)
}

func editHandler(w http.ResponseWriter, r *http.Request, title string) {
    p, err := loadPage(title)
    if err != nil {
        // then there was an error -- it doesn't exist yet!
        empty := &Edl{ Title: title }
        movieurl := r.URL.Query()["movieurl"][0];
        if strings.Contains(movieurl, "hulu") {
          empty.HuluUrl = movieurl
        } else if strings.Contains(movieurl, "netflix") {
          empty.NetflixURL = movieurl
        } else if strings.Contains(movieurl, "amazon.com") {
          empty.AmazonURL = movieurl
        } // else if strings.Contains(movieurl, 'play.google.com') { // youtube here too?
         
        empty.Mutes = []EditListEntry{EditListEntry{}}
        empty.Skips = []EditListEntry{EditListEntry{}}
        b, _ := empty.EdlToBytes()
        p = &Page{Title: title, Body: b}
    }
    renderTemplate(w, "edit", p)
}

// render template file for this action :)
func renderTemplate(w http.ResponseWriter, tmpl string, data interface{}) {
    t, err := template.ParseFiles(tmpl + ".html")
    if err != nil {
        http.Error(w, err.Error(), http.StatusInternalServerError)
        return
    }
    err = t.Execute(w, data)
    if err != nil {
        http.Error(w, err.Error(), http.StatusInternalServerError)
    }
}

func viewHandler(w http.ResponseWriter, r *http.Request, title string) {
    p, err := loadPage(title)
    if err != nil {
        http.Redirect(w, r, "/edit/" + title, http.StatusFound)
        return
    }
    if len(r.URL.Query()["raw"]) > 0 {
      fmt.Fprintf(w, "%s", p.Body)
    } else {
      renderTemplate(w, "view", p)
    }
    
}


func newHandler(w http.ResponseWriter, r *http.Request) {
    moviename := r.URL.Query()["moviename"][0];
    movieurl := r.URL.Query()["movieurl"][0];
    moviename = strings.Replace(moviename, " ", "-", -1)
    http.Redirect(w, r, "/edit/" + moviename + "?movieurl=" + movieurl, http.StatusFound) // edit pre-initializes it for us...plus what if it already exists somehow? hmm....
}

func allFileInfos() []os.FileInfo {
    files, _ := ioutil.ReadDir(DirName)
    return files
}

func allPages() []Page {
    paths := AllPaths()
    array2 := make([]Page, len(paths))
    for i, filename := range paths { 
      p, _ := loadPageFilename(filename)
      array2[i] = *p 
    }
    return array2
}

func AllPaths() []string {
    files := allFileInfos()
    array2 := make([]string, len(files))
    for i, f := range files { array2[i] = path.Join(DirName, f.Name()) }
    return array2
}


func indexHandler(w http.ResponseWriter, r *http.Request) {
    renderTemplate(w, "index", allPages())
}

func saveHandler(w http.ResponseWriter, r *http.Request, title string) {
    body := r.FormValue("body")
    p := &Page{Title: title, Body: []byte(body)}
    err := p.save()
    if err != nil {
        http.Error(w, err.Error(), http.StatusInternalServerError)
        return
    }
    http.Redirect(w, r, "/view/" + title, http.StatusFound)
}

func makeHandler(fn func(http.ResponseWriter, *http.Request, string)) http.HandlerFunc {
    return func(w http.ResponseWriter, r *http.Request) {
        path := r.URL.Path
        m := validPath.FindStringSubmatch(path)
        if m == nil {
            fmt.Println("bad path hacker found" + r.URL.Path)
            http.NotFound(w, r)
            return 
        }
        fn(w, r, m[2])
    }
}

func helloWorldHandler(w http.ResponseWriter, r *http.Request) {
    fmt.Fprintf(w, "Hi there")
}

func main() {
    if len(os.Args) > 1 {
      Morph()
      //CheckAll()
      os.Exit(0)
    }
    http.HandleFunc("/view/", makeHandler(viewHandler))
    http.HandleFunc("/edit/", makeHandler(editHandler))
    http.HandleFunc("/save/", makeHandler(saveHandler))
    http.HandleFunc("/", indexHandler)
    http.HandleFunc("/search", searchHandler)
    http.HandleFunc("/new", newHandler)
    http.HandleFunc("/hello_world", helloWorldHandler)
    fmt.Println("serving on 8888") 
    http.ListenAndServe(":8888", nil)
    fmt.Println("exiting")
}
