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

# download CA bundle and write straight to temp folder
cd $DESTINATION
mkdir ssl
curl -o ssl/cacert.pem https://curl.haxx.se/ca/cacert.pem
cd -


