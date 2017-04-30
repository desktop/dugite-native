# a more graceful way to compute checksums
path_to_sha256sum=$(which sha256sum)
if [ -x "$path_to_sha256sum" ] ; then
  alias shasum="sha256sum"
else
  alias shasum="shasum -a 256"
fi
