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
  FILE="dugite-native-$VERSION-ubuntu-$BUILD.tar.gz"
elif [ "$TARGET_PLATFORM" == "macOS" ]; then
  FILE="dugite-native-$VERSION-macOS-$BUILD.tar.gz"
elif [ "$TARGET_PLATFORM" == "win32" ]; then
  FILE="dugite-native-$VERSION-win32-$BUILD.tar.gz"
else
  echo "Unable to package Git for platform $TARGET_PLATFORM"
  exit 1
fi

echo ""
echo "Creating archive..."
tar -cvzf $FILE -C $DESTINATION .
if [ "$APPVEYOR" == "True" ]; then
  CHECKSUM=$(sha256sum $FILE | awk '{print $1;}')
else
  CHECKSUM=$(shasum -a 256 $FILE | awk '{print $1;}')
fi

SIZE=$(du -h $FILE | cut -f1)

echo "Package created: ${FILE}"
echo "Size: ${SIZE}"
echo "SHA256: ${CHECKSUM}"
