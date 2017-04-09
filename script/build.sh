#!/bin/bash
#
# Entry point to build process to support different platforms.
# Platforms have different ways to build Git and prepare the environment
# for packaging, so defer to the `build-*` files for more details
#

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SOURCE="./git"
DESTINATION="/tmp/build/git"

if [ "$TARGET_PLATFORM" == "ubuntu" ]; then
  sh "$DIR/build-ubuntu.sh" $SOURCE $DESTINATION
elif [ "$TARGET_PLATFORM" == "macOS" ]; then
  sh "$DIR/build-macos.sh" $SOURCE $DESTINATION
elif [ "$TARGET_PLATFORM" == "win32" ]; then
  sh "$DIR/build-win32.sh" $DESTINATION
else
  echo "Unable to build Git for platform $TARGET_PLATFORM"
  exit 1
fi
