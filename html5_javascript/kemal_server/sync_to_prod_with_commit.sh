git pull && git cam "$1"  # this one can fail if none, that's OK
git pom && curl https://playitmyway.inet2.org/sync_web_server
until $(curl --output /dev/null --silent --head --fail https://playitmyway.inet2.org); do
    printf '.'
    sleep 1
done
echo "server is back up and running again"
