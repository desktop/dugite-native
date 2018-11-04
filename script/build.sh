#!/bin/bash -e
#
# Entry point to build process to support different platforms.
# Platforms have different ways to build Git and prepare the environment
# for packaging, so defer to the `build-*` files for more details

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
export SOURCE="${BASEDIR}/git"
export DESTINATION="/tmp/build/git"
export CURL_INSTALL_DIR="/tmp/build/curl"

if [ "$TARGET_PLATFORM" == "ubuntu" ]; then
  bash "$CURRENT_DIR/build-ubuntu.sh"
elif [ "$TARGET_PLATFORM" == "macOS" ]; then
  bash "$CURRENT_DIR/build-macos.sh"
elif [ "$TARGET_PLATFORM" == "win32" ]; then
  bash "$CURRENT_DIR/build-win32.sh"
elif [ "$TARGET_PLATFORM" == "arm64" ]; then
  export BASEDIR=$(pwd)
  bash "$CURRENT_DIR/build-arm64.sh"
else
  echo "Unable to build Git for platform $TARGET_PLATFORM"
  exit 1
fi
