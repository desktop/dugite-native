echo "-- Test compiled Git LFS"

$DESTINATION/libexec/git-core/git-lfs --version

echo "-- Test clone operation with generated binary"

TEMP_CLONE_DIR=/tmp/clones
mkdir -p $TEMP_CLONE_DIR

cd "$DESTINATION/bin"
./git --version
GIT_CURL_VERBOSE=1 \
  GIT_TEMPLATE_DIR="$DESTINATION/share/git-core/templates" \
  GIT_SSL_CAINFO="$DESTINATION/ssl/cacert.pem" \
  GIT_EXEC_PATH="$DESTINATION/libexec/git-core" \
  PREFIX="$DESTINATION" \
  ./git clone https://github.com/git/git.github.io "$TEMP_CLONE_DIR/git.github.io"
cd - > /dev/null
