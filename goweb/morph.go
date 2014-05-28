package main

import ("fmt"
   "io/ioutil"
)


func Morph() {
  files := AllPaths()
  for _, filename := range files {
    body, _ := ioutil.ReadFile(filename)
    old := EdlOld{}
    old.StringToEdlOld(body)
  }
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
  fmt.Println("donemorph")
}
