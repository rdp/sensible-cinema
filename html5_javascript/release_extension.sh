echo "this doesn't rebuild the extension...fwiw...or bump the version...nor re-deploy to server"
rm -f *.zip
zip -r chrome_extension_release.zip chrome_extension
git commit -am "release extension..."
git pom
