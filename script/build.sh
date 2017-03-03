#!/bin/bash
#
# Entry point to build process to support different platforms.
# Platforms have different ways to build Git and prepare the environment
# for packaging, so defer to the `build-*` files for more details
#

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SOURCE="./git"
DESTINATION="/tmp/build/git"

if [ "$PLATFORM" == "ubuntu" ]; then
  sh "$DIR/build-ubuntu.sh" $SOURCE $DESTINATION
elif [ "$PLATFORM" == "macOS" ]; then
  sh "$DIR/build-macos.sh" $SOURCE $DESTINATION
elif [ "$PLATFORM" == "win32" ]; then
  sh "$DIR/build-win32.sh" $DESTINATION
else
  echo "Unable to build Git for platform $PLATFORM"
  exit 1
fi
