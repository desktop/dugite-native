#!/bin/bash
#
# Script for packaging artefacts into gzipped archive.
# Build scripts should handle platform-specific differences, so this
# script works off the assumption that everything at $DESTINATION is
# intended to be part of the archive.
#

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SOURCE="./git"
DESTINATION="/tmp/build/git"
BUILD="$TRAVIS_BUILD_NUMBER"

cd $SOURCE
VERSION=$(git describe --exact-match HEAD)
EXIT_CODE=$?

if [ "$EXIT_CODE" == "128" ]; then
  echo "Git commit does not have tag, cannot use version to build from"
  exit 1
fi
cd - > /dev/null

if ! [ -d "$DESTINATION" ]; then
  echo "No output found, exiting..."
  exit 1
fi

if [ "$APPVEYOR" == "True" ]; then
  BUILD=$APPVEYOR_BUILD_NUMBER
fi

if [ "$TARGET_PLATFORM" == "ubuntu" ]; then
  GZIP_FILE="dugite-native-$VERSION-ubuntu-$BUILD.tar.gz"
  LZMA_FILE="dugite-native-$VERSION-ubuntu-$BUILD.lzma"
elif [ "$TARGET_PLATFORM" == "macOS" ]; then
  GZIP_FILE="dugite-native-$VERSION-ubuntu-$BUILD.tar.gz"
  LZMA_FILE="dugite-native-$VERSION-macOS-$BUILD.lzma"
elif [ "$TARGET_PLATFORM" == "win32" ]; then
  GZIP_FILE="dugite-native-$VERSION-ubuntu-$BUILD.tar.gz"
  LZMA_FILE="dugite-native-$VERSION-win32-$BUILD.lzma"
else
  echo "Unable to package Git for platform $TARGET_PLATFORM"
  exit 1
fi

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
