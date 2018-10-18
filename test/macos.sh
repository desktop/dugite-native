#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ROOT="$DIR/.."
SOURCE="$ROOT/git"
DESTINATION="$ROOT/build/git"

GIT_LFS_VERSION=2.5.2 \
TARGET_PLATFORM=macOS \
GIT_LFS_CHECKSUM=eedb80c79f1d3106aa5f1496ddc505e1c1c86c290293d81fb20c5358c615fd74 \
. "$ROOT/script/build-macos.sh" $SOURCE $DESTINATION

echo "Archive contents:"
cd $DESTINATION
du -ah $DESTINATION
cd - > /dev/null

GZIP_FILE="dugite-native-$VERSION-macos-test.tar.gz"
LZMA_FILE="dugite-native-$VERSION-macos-test.lzma"

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