#!/bin/bash

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
    CFLAGS='-Wall -g -O2 -fstack-protector --param=ssp-buffer-size=4 -Wformat -Werror=format-security -D_FORTIFY_SOURCE=2' \
    LDFLAGS='-Wl,-Bsymbolic-functions -Wl,-z,relro'
cd -

GIT_LFS_FILE=git-lfs.tar.gz
curl -sL -o $GIT_LFS_FILE $GIT_LFS_URL
shasum -a 256 $GIT_LFS_FILE | awk '{print $1;}'
COMPUTED_SHA256=$(shasum -a 256 $GIT_LFS_FILE | awk '{print $1;}')
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
cd $DESTINATION
mkdir ssl
curl -sL -o ssl/cacert.pem https://curl.haxx.se/ca/cacert.pem
cd -


