#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if [ "$TRAVIS_OS_NAME" == "linux" ]; then
  sh "$DIR/build-ubuntu.sh" ./git "/tmp/build/git"
else
  echo "Unable to build Git for platform $TRAVIS_OS_NAME"
fi
