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

if [ "$TRAVIS_OS_NAME" == "linux" ]; then
  FILE="Git-$VERSION-ubuntu-$BUILD.tgz"
elif [ "$TRAVIS_OS_NAME" == "osx" ]; then
  FILE="Git-$VERSION-macOS-$BUILD.tgz"
else
  echo "Unable to build Git for platform $TRAVIS_OS_NAME"
  exit 1
fi

tar -cjf $FILE -C $DESTINATION .

echo "Package created: ${FILE}"
