package main

import ( "fmt"
        "io/ioutil"
        "net/http" // std lib
	"html/template"
        "regexp"
        "encoding/json"
        "os"
)

type Page struct {
    Title string
    Body  []byte
}

type EditListEntry struct {
  Start string
  End string
  Type string
  ExactType string
  Info string
}

type EDL struct {
  URL string
  Title string
  Mutes []EditListEntry
  Skips []EditListEntry
}

var validPath = regexp.MustCompile("^/(edit|save|view)/([a-zA-Z0-9]+)$") // security check

var DirName string = "/tmp"; // will be overwritten, can't assign nil?

func (p *Page) save() error {
    filename := DirName + "/" + p.Title + ".txt"
    return ioutil.WriteFile(filename, p.Body, 0600)
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
        emptyEDL := &EDL{URL: "http://...", Title: "title"}
        b, _ := json.MarshalIndent(emptyEDL, "", " ") // attempt to give a good pattern for them to edit with...
        p = &Page{Title: title, Body: b}
    }
    renderTemplate(w, "edit", p)
}

// render some template file for this action :)
func renderTemplate(w http.ResponseWriter, tmpl string, p *Page) {
    t, err := template.ParseFiles(tmpl + ".html")
    if err != nil {
        http.Error(w, err.Error(), http.StatusInternalServerError)
        return
    }
    err = t.Execute(w, p)
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

func saveHandler(w http.ResponseWriter, r *http.Request, title string) {
    body := r.FormValue("body")
    p := &Page{Title: title, Body: []byte(body)}
    err := p.save()
    if err != nil {
        http.Error(w, err.Error(), http.StatusInternalServerError)
        return
    }
    http.Redirect(w, r, "/view/"+title, http.StatusFound)
}

func makeHandler(fn func(http.ResponseWriter, *http.Request, string)) http.HandlerFunc {
    return func(w http.ResponseWriter, r *http.Request) {
        m := validPath.FindStringSubmatch(r.URL.Path)
        if m == nil {
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
  fmt.Println("will save to" + conf.DirName)
  DirName = conf.DirName
  os.MkdirAll(DirName, 0700)
  return conf
}


func main() {
    http.HandleFunc("/view/", makeHandler(viewHandler))
    http.HandleFunc("/edit/", makeHandler(editHandler))
    http.HandleFunc("/save/", makeHandler(saveHandler))
    readConfig()
    fmt.Println("serving on 8080") 
    http.ListenAndServe(":8080", nil)
    fmt.Println("exiting")
}
