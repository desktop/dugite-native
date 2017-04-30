#!/bin/bash
#
# Compiling Git for Linux and bundling Git LFS from upstream.
#

# fail on any non-zero exit code
set -e

# import aliases for commands that may differ across environments
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
. "$DIR/aliases.sh"

SOURCE=$1
DESTINATION=$2

echo "Building git at $SOURCE to $DESTINATION"

cd $SOURCE
make clean
DESTDIR="$DESTINATION" make install prefix=/ \
    NO_PERL=1 \
    NO_TCLTK=1 \
    NO_GETTEXT=1 \
    NO_OPENSSL=1 \
    NO_INSTALL_HARDLINKS=1 \
    CC='gcc' \
    CFLAGS='-Wall -g -O2 -fstack-protector --param=ssp-buffer-size=4 -Wformat -Werror=format-security -U_FORTIFY_SOURCE' \
    LDFLAGS='-Wl,-Bsymbolic-functions -Wl,-z,relro'
cd -

# download Git LFS, verify its the right contents, and unpack it
GIT_LFS_FILE=git-lfs.tar.gz
curl -sL -o $GIT_LFS_FILE $GIT_LFS_URL
COMPUTED_SHA256=$(shasum $GIT_LFS_FILE | awk '{print $1;}')
if [ "$COMPUTED_SHA256" = "$GIT_LFS_CHECKSUM" ]; then
  echo "Git LFS: checksums match"
  SUBFOLDER="$DESTINATION/libexec/git-core"
  tar -xf $GIT_LFS_FILE -C $SUBFOLDER --exclude='*.sh' --exclude="*.md" --strip-components=1
else
  echo "Git LFS: expected checksum $GIT_LFS_CHECKSUM but got $COMPUTED_SHA256"
  echo "aborting..."
  exit 1
fi

# download CA bundle and write straight to temp folder
# for more information: https://curl.haxx.se/docs/caextract.html
cd $DESTINATION
mkdir -p ssl
curl -sL -o ssl/cacert.pem https://curl.haxx.se/ca/cacert.pem
cd -
