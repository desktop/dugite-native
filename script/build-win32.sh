#!/bin/bash
#
# Repackaging Git for Windows and bundling Git LFS from upstream.
#

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

DESTINATION=$1
mkdir -p $DESTINATION

echo "-- Downloading MinGit"
GIT_FOR_WINDOWS_FILE=git-for-windows.zip
curl -sL -o $GIT_FOR_WINDOWS_FILE $GIT_FOR_WINDOWS_URL
COMPUTED_SHA256=$(computeChecksum $GIT_FOR_WINDOWS_FILE)
if [ "$COMPUTED_SHA256" = "$GIT_FOR_WINDOWS_CHECKSUM" ]; then
  echo "MinGit: checksums match"
  unzip -qq $GIT_FOR_WINDOWS_FILE -d $DESTINATION
else
  echo "MinGit: expected checksum $GIT_FOR_WINDOWS_CHECKSUM but got $COMPUTED_SHA256"
  echo "aborting..."
  exit 1
fi

# download Git LFS, verify its the right contents, and unpack it
echo "-- Bundling Git LFS"
GIT_LFS_FILE=git-lfs.zip
curl -sL -o $GIT_LFS_FILE $GIT_LFS_URL
COMPUTED_SHA256=$(computeChecksum $GIT_LFS_FILE)
if [ "$COMPUTED_SHA256" = "$GIT_LFS_CHECKSUM" ]; then
  echo "Git LFS: checksums match"
  SUBFOLDER="$DESTINATION/mingw64/libexec/git-core/"
  unzip -qq -j $GIT_LFS_FILE -x '*.md' -d $SUBFOLDER
else
  echo "Git LFS: expected checksum $GIT_LFS_CHECKSUM and got $COMPUTED_SHA256"
  echo "aborting..."
  exit 1
fi


echo "--LSing \$DESTINATION"
bash "ls $DESTINATION"
if [ "$WIN_ARCH" == "64" ]; then
  echo "--LSing \$DESTINATION/mingw64"
  bash "ls $DESTINATION/mingw64"
  echo "Using mingw64"
  SYSTEM_CONFIG="$DESTINATION/mingw64/etc/gitconfig"
else
  echo "--LSing \$DESTINATION/mingw32"
  bash "ls $DESTINATION/mingw32"
  echo "Using mingw32"
  SYSTEM_CONFIG="$DESTINATION/mingw32/etc/gitconfig"
fi

echo "-- Setting some system configuration values"
git config --file $SYSTEM_CONFIG core.symlinks "false"
git config --file $SYSTEM_CONFIG core.autocrlf "true"
git config --file $SYSTEM_CONFIG core.fscache "true"
git config --file $SYSTEM_CONFIG http.sslBackend "schannel"


# removing global gitattributes file
rm "$DESTINATION/mingw64/etc/gitattributes"
echo "-- Removing global gitattributes which handles certain file extensions"
