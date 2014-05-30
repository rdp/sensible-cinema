package main

import ( "fmt"
        "io/ioutil"
        "net/http"
	"html/template"
        "regexp"
        "os"
        "bytes"
        "errors"
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

func CheckEdlString(toBytes []byte) ([]byte, error) {
    var asObject Edl
    err := asObject.BytesToEdl(toBytes)
    if err != nil {
      return nil, err // never get here, basically it's too "loose"
    }
    b, _ := asObject.EdlToBytes()
    countMarshalled := bytes.Count(b, []byte(`"`))
    countIncoming := bytes.Count(toBytes, []byte(`"`))
    if countIncoming != countMarshalled {
      return nil, errors.New("miscount, possibly misspelling/malformatted or out of date?")
    } else {
      return b, nil
    }
}

func loadPage(title string) (*Page, error) {
    filename := DirName + "/" + title + ".txt"
    body, err := ioutil.ReadFile(filename)
    if err != nil {
        return nil, err
    }
    return &Page{Title: title, Body: body}, nil
} 

func editHandler(w http.ResponseWriter, r *http.Request, title string) {
    p, err := loadPage(title)
    if err != nil {
        // then there was an error
        empty := &Edl{ NetflixURL: "http://...", Title: "title" }
        empty.Mutes = []EditListEntry{EditListEntry{}}
        empty.Skips = []EditListEntry{EditListEntry{}}
        b, _ := empty.EdlToBytes()
        p = &Page{Title: title, Body: b}
    }
    renderTemplate(w, "edit", p)
}

// render some template file for this action :)
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
    moviename = strings.Replace(moviename, " ", "-", -1)
    http.Redirect(w, r, "/edit/" + moviename, http.StatusFound) // edit pre-initializes it for us...plus what if it already exists somehow? hmm....
}

func allFileInfos() []os.FileInfo {
    files, _ := ioutil.ReadDir(DirName)
    return files
}

func AllPaths() []string {
    files := allFileInfos()
    array2 := make([]string, len(files))
    for i, f := range files { array2[i] = path.Join(DirName, f.Name()) }
    return array2
}

func indexHandler(w http.ResponseWriter, r *http.Request) {
    files := allFileInfos()
    array2 := make([]string, len(files))
    for i, file := range files { array2[i] = strings.TrimSuffix(file.Name(), filepath.Ext(file.Name())) } // strip off .ext's
    renderTemplate(w, "index", array2)
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
        path = strings.TrimSuffix(path, filepath.Ext(path)) // TODO
        m := validPath.FindStringSubmatch(path)
        if m == nil {
            fmt.Println("bad path you hacker " + r.URL.Path)
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
      os.Exit(0)
    }
    http.HandleFunc("/view/", makeHandler(viewHandler))
    http.HandleFunc("/edit/", makeHandler(editHandler))
    http.HandleFunc("/save/", makeHandler(saveHandler))
    http.HandleFunc("/", indexHandler)
    http.HandleFunc("/new", newHandler)
    http.HandleFunc("/hello_world", helloWorldHandler)
    fmt.Println("serving on 8888") 
    http.ListenAndServe(":8888", nil)
    fmt.Println("exiting")
}
