#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SOURCE="./git"
DESTINATION="/tmp/build/git"


if [ "$TRAVIS_OS_NAME" == "linux" ]; then
  sh "$DIR/build-ubuntu.sh" $SOURCE $DESTINATION
elif [ "$TRAVIS_OS_NAME" == "osx" ]; then
  sh "$DIR/build-macos.sh" $SOURCE $DESTINATION
else
  echo "Unable to build Git for platform $TRAVIS_OS_NAME"
fi
