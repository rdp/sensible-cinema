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

type Page struct {
    Title string
    Body  []byte
    Edl*   Edl
}


func (edl *Edl) UrlString() string {
  urlString, _ := edl.UrlAndType()
  return urlString
}

func (edl *Edl) UrlType() string {
  _, urlType := edl.UrlAndType()
  return urlType
}

func (edl *Edl) UrlAndType() (string, string) {
    if edl.NetflixURL != "" {
      return edl.NetflixURL, "Netflix"
    } else if edl.AmazonURL != "" {
      return edl.AmazonURL, "Amazon"
    } else if edl.GooglePlayURL != "" {
      return edl.GooglePlayURL, "Google Play"
    } else if edl.HuluUrl != "" {
      return edl.HuluUrl, "Hulu" 
    } else {
      return "not set url", "unknown"
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

