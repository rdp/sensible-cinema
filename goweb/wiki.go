package main

import ( "fmt"
        "io/ioutil"
        "net/http"
	"html/template"
        "regexp"
        "encoding/json"
        "os"
        "bytes"
        "errors"
        "strings"
)

type Page struct {
    Title string
    Body  []byte
}

type EditListEntry struct {
  Start string
  End string
  Category string
  ExactTypeInCategory string
  AdditionalInfo string
  AdditionalInfo1 string
}

type EDL struct {
  NetflixURL string
  Title string
  Notes string
  Mutes []EditListEntry
  Skips []EditListEntry
}

var validPath = regexp.MustCompile("^/(edit|save|view)/([a-zA-Z0-9- ]+)$") // security check

var DirName string = "/tmp"; // will be overwritten, can't assign nil?

func (edl *EDL) marshal() ([]byte, error) {
    return json.MarshalIndent(edl, "", " ")  
}

func (edl *EDL) unmarshal(b []byte) error {
    return json.Unmarshal(b, edl)
}

func (p *Page) save() error {
    filename := DirName + "/" + p.Title + ".txt"
    // make sure if we encode it and decode it, it has the same number of quotes
    // which would imply that it parses right to our object, at least :P
    var asObject EDL
    err := asObject.unmarshal(p.Body)
    if err != nil {
      return err // never get here, basically it's too "loose"
    }
    b, _ := asObject.marshal()
    countMarshalled := bytes.Count(b, []byte(`"`))
    countIncoming := bytes.Count(p.Body, []byte(`"`))
    if countIncoming != countMarshalled {
      return errors.New("miscount, possibly misspelling/malformatted?")
    } else { 
      return ioutil.WriteFile(filename, b, 0600) // write re-prettified...
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
        empty := &EDL{ NetflixURL: "http://...", Title: "title" }
        empty.Mutes = []EditListEntry{EditListEntry{}}
        empty.Skips = []EditListEntry{EditListEntry{}}
        b, _ := empty.marshal()
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
    renderTemplate(w, "view", p)
}

func newHandler(w http.ResponseWriter, r *http.Request) {
    moviename := r.URL.Query()["moviename"][0];
    moviename = strings.Replace(moviename, " ", "-", -1)
    http.Redirect(w, r, "/edit/" + moviename, http.StatusFound) // edit pre-initializes it for us...plus what if it already exists somehow? hmm....
}

func indexHandler(w http.ResponseWriter, r *http.Request) {
    files, _ := ioutil.ReadDir(DirName)
    renderTemplate(w, "index", files)
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
        m := validPath.FindStringSubmatch(r.URL.Path)
        if m == nil {
            fmt.Println("bad path you hacker")
            http.NotFound(w, r)
            return 
        }
        fn(w, r, m[2])
    }
}

type Configuration struct {
    DirName    string
}

func readConfig() Configuration {
  conf := Configuration{}
  file, _ := os.Open("conf.json")
  decoder := json.NewDecoder(file)
  err := decoder.Decode(&conf)
  if err != nil {
    fmt.Println("error:", err)
  }
  fmt.Println("will be saving to" + conf.DirName)
  DirName = conf.DirName
  os.MkdirAll(DirName, 0700)
  return conf
}


func main() {
    readConfig()
    http.HandleFunc("/view/", makeHandler(viewHandler))
    http.HandleFunc("/edit/", makeHandler(editHandler))
    http.HandleFunc("/save/", makeHandler(saveHandler))
    http.HandleFunc("/", indexHandler)
    http.HandleFunc("/new", newHandler)
    fmt.Println("serving on 8080") 
    http.ListenAndServe(":8080", nil)
    fmt.Println("exiting")
}

// TODO migrateMain with duplicate structs...
