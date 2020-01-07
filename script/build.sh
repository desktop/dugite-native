#!/bin/bash -e
#
# Entry point to build process to support different platforms.
# Platforms have different ways to build Git and prepare the environment
# for packaging, so defer to the `build-*` files for more details

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if [ "$TARGET_PLATFORM" == "ubuntu" ]; then
  SCRIPT="$CURRENT_DIR/build-ubuntu.sh"
elif [ "$TARGET_PLATFORM" == "macOS" ]; then
  SCRIPT="$CURRENT_DIR/build-macos.sh"
elif [ "$TARGET_PLATFORM" == "win32" ]; then
  SCRIPT="$CURRENT_DIR/build-win32.sh"
else
  echo "Unable to build Git for platform $TARGET_PLATFORM"
  exit 1
fi

ROOT=$(dirname "$CURRENT_DIR")

BASEDIR=$ROOT \
  SOURCE="$ROOT/git" \
  DESTINATION="/tmp/build/git" \
  CURL_INSTALL_DIR="/tmp/build/curl" \
  bash "$SCRIPT"
