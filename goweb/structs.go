package main

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
  Title string
  Notes string
  Mutes []EditListEntry
  Skips []EditListEntry
}

