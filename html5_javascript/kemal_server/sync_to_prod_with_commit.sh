git pull && git cam "$1"  # this one can fail if none
git pom && curl https://playitmyway.inet2.org/sync_web_server
echo "remember if you break the compile, the auto part will die"
until $(curl --output /dev/null --silent --head --fail https://playitmyway.inet2.org); do
    printf '.'
    sleep 1
done
