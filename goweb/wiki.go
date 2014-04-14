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

var validPath = regexp.MustCompile("^/(edit|save|view)/([a-zA-Z0-9]+)$") // security check

func (p *Page) save() error {
    filename := p.Title + ".txt"
    return ioutil.WriteFile(filename, p.Body, 0600)
}

func loadPage(title string) (*Page, error) {
    filename := title + ".txt"
    body, err := ioutil.ReadFile(filename)
    if err != nil {
        return nil, err
    }
    return &Page{Title: title, Body: body}, nil
}

func main_old() { // just writes a file, loads it, outputs it...
    p1 := &Page{Title: "TestPage", Body: []byte("This is a sample Page.")}
    p1.save()
    p2, _ := loadPage("TestPage")
    fmt.Println(string(p2.Body))
}

func handler(w http.ResponseWriter, r *http.Request) { // unused
    fmt.Fprintf(w, "Hi there, I love %s!", r.URL.Path[1:])
}

func editHandler(w http.ResponseWriter, r *http.Request, title string) {
    p, err := loadPage(title)
    if err != nil {
        p = &Page{Title: title}
    }
    renderTemplate(w, "edit", p)
}

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
        http.Redirect(w, r, "/edit/"+title, http.StatusFound)
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
  return conf
}

func main() {
    http.HandleFunc("/view/", makeHandler(viewHandler))
    http.HandleFunc("/edit/", makeHandler(editHandler))
    http.HandleFunc("/save/", makeHandler(saveHandler))
    //fmt.Println("serving on 8080") 
    //http.ListenAndServe(":8080", nil)
    a := readConfig()
    fmt.Println(a.DirName)
}
