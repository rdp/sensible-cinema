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
  Title string
  Notes string
  Mutes []EditListEntry
  Skips []EditListEntry
}

type EdlOld struct {
  NetflixURL string
  AmazonURL string
  Title string
  Notes string
  Mutes []EditListEntry
  Skips []EditListEntry
}

func (edl *Edl) EdlToString() ([]byte, error) {
    return json.MarshalIndent(edl, "", " ") // pretty print
}

func (edl *Edl) EdlOldToString() ([]byte, error) {
    return json.MarshalIndent(edl, "", " ") // pretty print
}

func (edl *Edl) StringToEdl(b []byte) error {
    return json.Unmarshal(b, edl)
}

func (edl *EdlOld) StringToEdlOld(b []byte) error {
    return json.Unmarshal(b, edl)
}

