echo "make sure it doesn't point to dev!"
rm -f *.zip
zip -r chrome_extension_release.zip chrome_extension
git commit -am "release extension..."
