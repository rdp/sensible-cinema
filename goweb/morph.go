package main

import ("fmt"
    "os")

func main2() {
    if ReadConfig() != nil {
      os.Exit(1)
    }

  files := AllFiles()
  for _, file := range files {
    fmt.Println("hello",file)
  }
  fmt.Println("hello")
}
