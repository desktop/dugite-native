#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ROOT="$DIR/.."
SOURCE="$ROOT/git"
DESTINATION="$ROOT/build/git"

GIT_FOR_WINDOWS_URL=https://github.com/git-for-windows/git/releases/download/v2.17.1.windows.2/MinGit-2.17.1.2-64-bit.zip \
GIT_FOR_WINDOWS_CHECKSUM=52e611a411cd58eaaab8218bb917cb4410b0c5733f234be6e581c6a9821b30ea \
GIT_LFS_URL=https://github.com/git-lfs/git-lfs/releases/download/v2.4.2/git-lfs-windows-amd64-2.4.2.zip \
GIT_LFS_CHECKSUM=4c95d8e842ef55013c8ac99c4ffcad2a20a41bc41bd8e0943a228a03e07cd976 \
. "$ROOT/script/build-win32.sh" $SOURCE $DESTINATION

echo "Archive contents:"
cd $DESTINATION
du -ah $DESTINATION
cd - > /dev/null

GZIP_FILE="dugite-native-$VERSION-win32-test.tar.gz"
LZMA_FILE="dugite-native-$VERSION-win32-test.lzma"

echo ""
echo "Creating archives..."
if [ "$(uname -s)" == "Darwin" ]; then
  tar -czf $GZIP_FILE -C $DESTINATION .
  tar --lzma -cf $LZMA_FILE -C $DESTINATION .
else
  tar -caf $GZIP_FILE -C $DESTINATION .
  tar -caf $LZMA_FILE -C $DESTINATION .
fi

if [ "$APPVEYOR" == "True" ]; then
  GZIP_CHECKSUM=$(sha256sum $GZIP_FILE | awk '{print $1;}')
  LZMA_CHECKSUM=$(sha256sum $LZMA_FILE | awk '{print $1;}')
else
  GZIP_CHECKSUM=$(shasum -a 256 $GZIP_FILE | awk '{print $1;}')
  LZMA_CHECKSUM=$(shasum -a 256 $LZMA_FILE | awk '{print $1;}')
fi

GZIP_SIZE=$(du -h $GZIP_FILE | cut -f1)
LZMA_SIZE=$(du -h $LZMA_FILE | cut -f1)

echo "Packages created:"
echo "${GZIP_FILE} - ${GZIP_SIZE} - checksum: ${GZIP_CHECKSUM}"
echo "${LZMA_FILE} - ${LZMA_SIZE} - checksum: ${LZMA_CHECKSUM}"