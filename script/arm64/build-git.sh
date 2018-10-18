#!/bin/bash -e

if [[ -z "${SOURCE}" ]]; then
  echo "Required environment variable SOURCE was not set"
  exit 1
fi

if [[ -z "${DESTINATION}" ]]; then
  echo "Required environment variable DESTINATION was not set"
  exit 1
fi

echo " -- Building git at $SOURCE to $DESTINATION"

cd "$SOURCE"
make clean
DESTDIR="$DESTINATION" make strip install prefix=/ \
    NO_PERL=1 \
    NO_TCLTK=1 \
    NO_GETTEXT=1 \
    NO_INSTALL_HARDLINKS=1 \
    CC='gcc' \
    CFLAGS='-Wall -g -O2 -fstack-protector --param=ssp-buffer-size=4 -Wformat -Werror=format-security -U_FORTIFY_SOURCE' \
    LDFLAGS='-Wl,-Bsymbolic-functions -Wl,-z,relro'

echo "-- Removing server-side programs"
rm -f "$DESTINATION/bin/git-cvsserver"
rm -f "$DESTINATION/bin/git-receive-pack"
rm -f "$DESTINATION/bin/git-upload-archive"
rm -f "$DESTINATION/bin/git-upload-pack"
rm -f "$DESTINATION/bin/git-shell"

echo "-- Removing unsupported features"
rm -f "$DESTINATION/libexec/git-core/git-svn"
rm -f "$DESTINATION/libexec/git-core/git-remote-testsvn"
rm -f "$DESTINATION/libexec/git-core/git-p4"

# because we are building Git in a container, we need to ensure the regular
# user is able to modify the output outside of this script
chmod 777 "$DESTINATION/libexec/git-core"

(
# download CA bundle and write straight to temp folder
# for more information: https://curl.haxx.se/docs/caextract.html
echo "-- Adding CA bundle"
cd "$DESTINATION"
mkdir -p ssl
curl -sL -o ssl/cacert.pem https://curl.haxx.se/ca/cacert.pem
cd - > /dev/null
)