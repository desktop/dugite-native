#!/bin/bash
#
# Entry point to build process to support different platforms.
# Platforms have different ways to build Git and prepare the environment
# for packaging, so defer to the `build-*` files for more details
#

# a more graceful way to compute checksums

computeChecksum() {
   if [ -z "$1" ] ; then
     # no parameter provided, fail hard
     exit 1
   fi

  path_to_sha256sum=$(which sha256sum)
  if [ -x "$path_to_sha256sum" ] ; then
    echo $(sha256sum $1 | awk '{print $1;}')
  else
    echo $(shasum -a 256 $1 | awk '{print $1;}')
  fi
}

export -f computeChecksum

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
