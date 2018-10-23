#!/bin/bash
#
# Compiling Git for Linux and bundling Git LFS from upstream.
#

SOURCE=$1
DESTINATION=$2
CURL_INSTALL_DIR=$3

# i want to centralize this function but everything is terrible
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

echo " -- Building vanilla curl at $CURL_INSTALL_DIR instead of distro-specific version"

CURL_FILE_NAME="curl-7.61.1"
CURL_FILE="$CURL_FILE_NAME.tar.gz"

cd /tmp
curl -LO "https://curl.haxx.se/download/$CURL_FILE"
tar -xf $CURL_FILE
cd $CURL_FILE_NAME
./configure --prefix=$CURL_INSTALL_DIR
make install
cd - > /dev/null

echo " -- Building git at $SOURCE to $DESTINATION"

cd $SOURCE
make clean
make configure
CC='gcc' \
  CFLAGS='-Wall -g -O2 -fstack-protector --param=ssp-buffer-size=4 -Wformat -Werror=format-security -U_FORTIFY_SOURCE' \
  LDFLAGS='-Wl,-Bsymbolic-functions -Wl,-z,relro' \
  ./configure \
  --with-curl=$CURL_INSTALL_DIR \
  --prefix=/
DESTDIR="$DESTINATION" \
  NO_TCLTK=1 \
  NO_GETTEXT=1 \
  NO_INSTALL_HARDLINKS=1 \
  NO_R_TO_GCC_LINKER=1 \
  make strip install
cd - > /dev/null


if [[ "$GIT_LFS_VERSION" ]]; then
  echo "-- Bundling Git LFS"
  GIT_LFS_FILE=git-lfs.tar.gz
  GIT_LFS_URL="https://github.com/git-lfs/git-lfs/releases/download/v${GIT_LFS_VERSION}/git-lfs-linux-amd64-v${GIT_LFS_VERSION}.tar.gz"
  echo "-- Downloading from $GIT_LFS_URL"
  curl -sL -o $GIT_LFS_FILE $GIT_LFS_URL
  COMPUTED_SHA256=$(computeChecksum $GIT_LFS_FILE)
  if [ "$COMPUTED_SHA256" = "$GIT_LFS_CHECKSUM" ]; then
    echo "Git LFS: checksums match"
    SUBFOLDER="$DESTINATION/libexec/git-core"
    tar -xvf $GIT_LFS_FILE -C $SUBFOLDER --exclude='*.sh' --exclude="*.md"

    if [[ ! -f "$SUBFOLDER/git-lfs" ]]; then
      echo "After extracting Git LFS the file was not found under libexec/git-core/"
      echo "aborting..."
      exit 1
    fi
  else
    echo "Git LFS: expected checksum $GIT_LFS_CHECKSUM but got $COMPUTED_SHA256"
    echo "aborting..."
    exit 1
  fi
else
  echo "-- Skipped bundling Git LFS (set GIT_LFS_VERSION to include it in the bundle)"
fi


# download CA bundle and write straight to temp folder
# for more information: https://curl.haxx.se/docs/caextract.html
echo "-- Adding CA bundle"
cd $DESTINATION
mkdir -p ssl
curl -sL -o ssl/cacert.pem https://curl.haxx.se/ca/cacert.pem
cd - > /dev/null

if [[ ! -f "$DESTINATION/ssl/cacert.pem" ]]; then
  echo "-- Skipped bundling of CA certificates (failed to download them)"
fi


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


checkStaticLinking() {
  if [ -z "$1" ] ; then
    # no parameter provided, fail hard
    exit 1
  fi

  # ermagherd there's two whitespace characters between 'LSB' and 'executable'
  # when running this on Travis - why is everything so terrible?
  if file $1 | grep -q 'ELF 64-bit LSB'; then
    if readelf -d $1 | grep -q 'Shared library'; then
      echo "File: $file"
      # this is done twice rather than storing in a bash variable because
      # it's easier than trying to preserve the line endings
      echo "readelf output:"
      readelf -d $1 | grep 'Shared library'
      # get a list of glibc versions required by the binary
      echo "objdump GLIBC output:"
      objdump -T $1 | grep -oEi 'GLIBC_[0-9]*.[0-9]*.[0-9]*'| sort | uniq
      # confirm what version of curl is expected
      echo "objdump curl output:"
      objdump -T $1 | grep -oEi " curl.*" | sort | uniq
      echo ""
    fi
  fi
}

echo "-- Static linking research"
cd "$DESTINATION"
# check all files for ELF exectuables
find . -type f -print0 | while read -d $'\0' file
do
  checkStaticLinking $file
done
cd - > /dev/null
