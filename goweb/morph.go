package main

import ("fmt"
    "os")

func main() {
  if ReadConfig() != nil {
    os.Exit(1)
  }

  files := AllFiles()
  for _, file := range files {
    fmt.Println("hello",file)
    // EdlOldToString ...
  }
  fmt.Println("hello")
}
