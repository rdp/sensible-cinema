package main

import "encoding/json"

type EditListEntry struct {
  Start string
  End string
  Category string
  ExactTypeInCategory string
  AdditionalInfo string
  AdditionalInfo1 string
}

type Edl struct {
  NetflixURL string
  AmazonURL string
  GooglePlayURL string
  HuluUrl string
  Title string
  Notes string
  Mutes []EditListEntry
  Skips []EditListEntry
}

type EdlOld struct {
  NetflixURL string
  AmazonURL string
  GooglePlayURL string
  HuluUrl string
  Title string
  Notes string
  Mutes []EditListEntry
  Skips []EditListEntry
}

func (edl *Edl) UrlString() string {
    if edl.NetflixURL != "" {
      return edl.NetflixURL
    } else if edl.AmazonURL != "" {
      return edl.AmazonURL
    } else if edl.GooglePlayURL != "" {
      return edl.GooglePlayURL
    } else {
      return edl.HuluUrl // nil ok :)
    }
}

func (edl *Edl) EdlToBytes() ([]byte, error) {
    return json.MarshalIndent(edl, "", " ") // pretty print
}

func (edl *Edl) EdlOldToBytes() ([]byte, error) {
    return json.MarshalIndent(edl, "", " ") // pretty print
}

func (edl *Edl) BytesToEdl(b []byte) error {
    return json.Unmarshal(b, edl)
}

func (edl *EdlOld) BytesToEdlOld(b []byte) error {
    return json.Unmarshal(b, edl)
}

