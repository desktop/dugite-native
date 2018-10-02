#!/bin/bash
#
# Compiling Git for macOS and bundling Git LFS from upstream.
#

SOURCE=$1
DESTINATION=$2

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

echo "-- Building git at $SOURCE to $DESTINATION"

cd $SOURCE
make clean
DESTDIR="$DESTINATION" make strip install prefix=/ \
    NO_PERL=1 \
    NO_TCLTK=1 \
    NO_GETTEXT=1 \
    NO_DARWIN_PORTS=1 \
    NO_INSTALL_HARDLINKS=1 \
    MACOSX_DEPLOYMENT_TARGET=10.9
cd - > /dev/null

echo "-- Bundling Git LFS"
GIT_LFS_FILE=git-lfs.tar.gz
GIT_LFS_URL="https://github.com/git-lfs/git-lfs/releases/download/v${GIT_LFS_VERSION}/git-lfs-darwin-amd64-v${GIT_LFS_VERSION}.tar.gz"
echo "-- Downloading from $GIT_LFS_URL"
curl -sL -o $GIT_LFS_FILE $GIT_LFS_URL
COMPUTED_SHA256=$(computeChecksum $GIT_LFS_FILE)
if [ "$COMPUTED_SHA256" = "$GIT_LFS_CHECKSUM" ]; then
  echo "Git LFS: checksums match"
  SUBFOLDER="$DESTINATION/libexec/git-core"
  # strip out any text files when extracting the Git LFS archive
  tar -xvf $GIT_LFS_FILE -C $SUBFOLDER --exclude='*.sh' --exclude='*.md'

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

echo "-- Bundling smimesign"
SMIMESIGN_FILE=smimesign.tar.gz
SMIMESIGN_URL="https://github.com/github/smimesign/releases/download/${SMIMESIGN_VERSION}/smimesign-${SMIMESIGN_VERSION}-macos.tgz"
echo "-- Downloading from $SMIMESIGN_URL"
curl -sL -o $SMIMESIGN_FILE $SMIMESIGN_URL
COMPUTED_SHA256=$(computeChecksum $SMIMESIGN_FILE)
if [ "$COMPUTED_SHA256" = "$SMIMESIGN_CHECKSUM" ]; then
  echo "smimesign: checksums match"
  SUBFOLDER="$DESTINATION/bin"
  tar -xvf $SMIMESIGN_FILE -C $SUBFOLDER

  if [[ ! -f "$SUBFOLDER/smimesign" ]]; then
    echo "After extracting smimesign the file was not found under bin/"
    echo "aborting..."
    exit 1
  fi
else
  echo "smimesign: expected checksum $SMIMESIGN_CHECKSUM but got $COMPUTED_SHA256"
  echo "aborting..."
  exit 1
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
