#!/bin/bash
#
# Compiling Git for ARM64 Linux (should be run inside a container)
#
# Required environment variables:
# - SOURCE
# - DESTINATION
# - CURL_INSTALL_DIR

echo " -- Building git at $SOURCE to $DESTINATION"

cd "$SOURCE" || exit 1
make clean
make configure
CC='gcc' \
  CFLAGS='-Wall -g -O2 -fstack-protector --param=ssp-buffer-size=4 -Wformat -Werror=format-security -U_FORTIFY_SOURCE' \
  LDFLAGS='-Wl,-Bsymbolic-functions -Wl,-z,relro' \
  ./configure \
  --with-curl="$CURL_INSTALL_DIR" \
  --prefix=/

DESTDIR="$DESTINATION" \
    NO_PERL=1 \
    NO_TCLTK=1 \
    NO_GETTEXT=1 \
    NO_INSTALL_HARDLINKS=1 \
    NO_R_TO_GCC_LINKER=1 \
    make strip install

echo "-- Removing server-side programs"
rm "$DESTINATION/bin/git-cvsserver"
rm "$DESTINATION/bin/git-receive-pack"
rm "$DESTINATION/bin/git-upload-archive"
rm "$DESTINATION/bin/git-upload-pack"
rm "$DESTINATION/bin/git-shell"

echo "-- Removing unsupported features"
rm "$DESTINATION/libexec/git-core/git-svn"
rm "$DESTINATION/libexec/git-core/git-remote-testsvn"
rm "$DESTINATION/libexec/git-core/git-p4"
chmod 777 "$DESTINATION/libexec/git-core"
