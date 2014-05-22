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

type EDL struct {
  NetflixURL string
  AmazonURL string
  GooglePlayURL string
  Title string
  Notes string
  Mutes []EditListEntry
  Skips []EditListEntry
}

type EDLOld struct {
  NetflixURL string
  AmazonURL string
  Title string
  Notes string
  Mutes []EditListEntry
  Skips []EditListEntry
}

func (edl *EDL) EdlToString() ([]byte, error) {
    return json.MarshalIndent(edl, "", " ") // pretty print
}

func (edl *EDL) EdlOldToString() ([]byte, error) {
    return json.MarshalIndent(edl, "", " ") // pretty print
}

func (edl *EDL) StringToEdl(b []byte) error {
    return json.Unmarshal(b, edl)
}

func (edl *EDLOld) StringToEdlOld(b []byte) error {
    return json.Unmarshal(b, edl)
}

