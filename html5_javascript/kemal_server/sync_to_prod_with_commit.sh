git pull && (git cam "$1" || git cam "a commit")  # this one can fail if none, that's OK
git pom && curl https://playitmyway.org/sync_web_server
until $(curl --output /dev/null --silent --head --fail https://playitmyway.org); do
    printf '.'
    sleep 1
done
echo "server is back up and running again"
