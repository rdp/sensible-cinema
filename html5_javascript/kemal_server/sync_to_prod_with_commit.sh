git pull && (git cam "$1" || git cam "a commit")  # this one can fail if none, that's OK
git pom 
echo "waiting for server to rebuild.."
curl https://playitmyway.org/sync_web_server || exit 1
until $(curl --output /dev/null --silent --head --fail https://playitmyway.org); do
    printf '.'
    sleep 1
done
echo "server is back up and running again [or still running]"
