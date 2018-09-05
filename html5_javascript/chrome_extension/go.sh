scriptdir=$(cd -P -- "$(dirname -- "$0")" && pwd -P)
cd $scriptdir
crystal ./generate_it.cr && echo "regenerated plugin"
