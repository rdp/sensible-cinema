package main

import ("fmt"
   "io/ioutil"
)


func Morph() {
  files := AllPaths()
  for _, filename := range files {
    body, _ := ioutil.ReadFile(filename)
    // old := EdlOld{} // don't need anything this complex for a simple add :)
    // old.StringToEdlOld(body)
    new := Edl{}
    new.BytesToEdl(body)
    newBody, _ := new.EdlToBytes()
    _ = ioutil.WriteFile(filename, newBody, 0600)
  }
  fmt.Println("done morph -- update structs file now if they all pass -- also retest it against the client!")
  CheckAll()
}

func CheckAll() {
  files := AllPaths()
  for _, filename := range files {
    body, _ := ioutil.ReadFile(filename)
    _, err := CheckEdlString(body);
    if err != nil {
      fmt.Println("probably got a bad/old one:" + filename) 
    } else {
      fmt.Println("got a good one" + filename)
    }
    // EdlOldToString ...
  }
  fmt.Println("done CheckAll")
}
