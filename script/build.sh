#!/bin/bash
#
# Entry point to build process to support different platforms.
# Platforms have different ways to build Git and prepare the environment
# for packaging, so defer to the `build-*` files for more details
#
BASEDIR=$(pwd)
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SOURCE="${BASEDIR}/git"
DESTINATION="/tmp/build/git"
CURL_INSTALL_DIR="/tmp/build/curl"

if [ "$TARGET_PLATFORM" == "ubuntu" ]; then
  bash "$DIR/build-ubuntu.sh" "$SOURCE" $DESTINATION $CURL_INSTALL_DIR
elif [ "$TARGET_PLATFORM" == "macOS" ]; then
  bash "$DIR/build-macos.sh" "$SOURCE" $DESTINATION
elif [ "$TARGET_PLATFORM" == "win32" ]; then
  bash "$DIR/build-win32.sh" $DESTINATION
elif [ "$TARGET_PLATFORM" == "arm64" ]; then
  bash "$DIR/build-arm64.sh" "$SOURCE" "$DESTINATION" "$CURL_INSTALL_DIR" "$BASEDIR"
else
  echo "Unable to build Git for platform $TARGET_PLATFORM"
  exit 1
fi
