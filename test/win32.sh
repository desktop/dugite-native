#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ROOT="$DIR/.."
SOURCE="$ROOT/git"
DESTINATION="$ROOT/build/git"

GIT_FOR_WINDOWS_URL=https://github.com/git-for-windows/git/releases/download/v2.15.1.windows.1/MinGit-2.15.1-64-bit.zip \
GIT_FOR_WINDOWS_CHECKSUM=5e38d13241b0742e6673bc5116ac82e851dd1fad01c660c943017f4549b6afea \
GIT_LFS_URL=https://github.com/git-lfs/git-lfs/releases/download/v2.3.4/git-lfs-windows-amd64-2.3.4.zip \
GIT_LFS_CHECKSUM=18c47fd2806659e81a40fbd6f6b0598ea1802635ce04fb2317d75973450a3fe5 \
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