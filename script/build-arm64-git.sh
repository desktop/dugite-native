echo " -- Building git at $SOURCE to $DESTINATION"
apt-get update
apt-get install -y build-essential libexpat-dev libcurl4-openssl-dev zlib1g-dev libssl-dev

cd $SOURCE
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
