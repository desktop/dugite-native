#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ROOT="$DIR/.."
SOURCE="$ROOT/git"
DESTINATION="$ROOT/build/git"

GIT_LFS_VERSION=2.5.2 \
TARGET_PLATFORM=win32 \
WIN_ARCH=32 \
GIT_FOR_WINDOWS_URL=https://github.com/git-for-windows/git/releases/download/v2.19.1.windows.1/MinGit-2.19.1-32-bit.zip \
GIT_FOR_WINDOWS_CHECKSUM=9bde728fe03f66a022b3e41408902ccfceb56a34067db1f35d6509375b9be922 \
GIT_LFS_CHECKSUM=6cf7d4c169a17dd5b326f903708829e7471368b7e1235ab150ce77555f47b213 \
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

echo "${GZIP_CHECKSUM}" | tr -d '\n' > "${GZIP_FILE}.sha256"
echo "${LZMA_CHECKSUM}" | tr -d '\n' > "${LZMA_FILE}.sha256"

echo "Packages created:"
echo "${GZIP_FILE} - ${GZIP_SIZE} - checksum: ${GZIP_CHECKSUM}"
echo "${LZMA_FILE} - ${LZMA_SIZE} - checksum: ${LZMA_CHECKSUM}"