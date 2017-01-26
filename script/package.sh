#!/bin/bash

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
cd -

if ! [ -d "$DESTINATION" ]; then
  echo "No output found, exiting..."
  exit 1
fi

if [ "$PLATFORM" == "ubuntu" ]; then
  FILE="Git-$VERSION-ubuntu-$BUILD.tgz"
elif [ "$PLATFORM" == "macOS" ]; then
  FILE="Git-$VERSION-macOS-$BUILD.tgz"
elif [ "$PLATFORM" == "win32" ]; then
  FILE="Git-$VERSION-win32-$BUILD.tgz"
else
  echo "Unable to package Git for platform $PLATFORM"
  exit 1
fi

tar -cvjf $FILE -C $DESTINATION .
CHECKSUM=$(shasum -a 256 $FILE | awk '{print $1;}')

echo "Package created: ${FILE}"
echo "SHA256: ${CHECKSUM}"
