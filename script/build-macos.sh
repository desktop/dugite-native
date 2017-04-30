#!/bin/bash
#
# Compiling Git for macOS and bundling Git LFS from upstream.
#

# fail on any non-zero exit code
set -e

# i want to centralize this script but everything is terrible
# go read https://github.com/desktop/dugite-native/issues/38
computeChecksum() {
   if [ -z "$1" ] ; then
     # no parameter provided, fail hard
     exit 1
   fi

  path_to_sha256sum=$(which sha256sum)
  if [ -x "$path_to_sha256sum" ] ; then
    echo $(sha256sum $1 | awk '{print $1;}')
  else
    echo $(shasum -a 256 $1 | awk '{print $1;}')
  fi
}

SOURCE=$1
DESTINATION=$2

echo "-- Building git at $SOURCE to $DESTINATION"

cd $SOURCE
make clean
DESTDIR="$DESTINATION" make install prefix=/ \
    NO_PERL=1 \
    NO_TCLTK=1 \
    NO_GETTEXT=1 \
    NO_DARWIN_PORTS=1 \
    NO_INSTALL_HARDLINKS=1 \
    MACOSX_DEPLOYMENT_TARGET=10.9
cd - > /dev/null

# download Git LFS, verify its the right contents, and unpack it
GIT_LFS_FILE=git-lfs.tar.gz
echo "-- Downloading Git LFS"
curl -sL -o $GIT_LFS_FILE $GIT_LFS_URL
COMPUTED_SHA256=$(computeChecksum $GIT_LFS_FILE)
if [ "$COMPUTED_SHA256" = "$GIT_LFS_CHECKSUM" ]; then
  echo "Git LFS: checksums match"
  SUBFOLDER="$DESTINATION/libexec/git-core"
  # strip out any text files when extracting the Git LFS archive
  tar -xf $GIT_LFS_FILE -C $SUBFOLDER --exclude='*.sh' --exclude='*.md'  --strip-components=1
else
  echo "Git LFS: expected checksum $GIT_LFS_CHECKSUM but got $COMPUTED_SHA256"
  echo "aborting..."
  exit 1
fi
