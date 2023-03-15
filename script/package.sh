#!/bin/bash -e
#
# Script for packaging artefacts into gzipped archive.
# Build scripts should handle platform-specific differences, so this
# script works off the assumption that everything at $DESTINATION is
# intended to be part of the archive.

set -eu -o pipefail

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SOURCE="./git"
DESTINATION="/tmp/build/git"

# shellcheck source=script/compute-checksum.sh
source "$CURRENT_DIR/compute-checksum.sh"

VERSION=$(
  cd $SOURCE || exit 1
  VERSION=$(git describe --exact-match HEAD)
  EXIT_CODE=$?

  if [ "$EXIT_CODE" == "128" ]; then
    echo "Git commit does not have tag, cannot use version to build from"
    exit 1
  fi
  echo "$VERSION"
)

BUILD_HASH=$(git rev-parse --short HEAD)

if ! [ -d "$DESTINATION" ]; then
  echo "No output found, exiting..."
  exit 1
fi

if [ "$TARGET_PLATFORM" == "ubuntu" ]; then
  GZIP_FILE="dugite-native-$VERSION-$BUILD_HASH-ubuntu-$TARGET_ARCH.tar.gz"
  LZMA_FILE="dugite-native-$VERSION-$BUILD_HASH-ubuntu-$TARGET_ARCH.lzma"
elif [ "$TARGET_PLATFORM" == "macOS" ]; then
  GZIP_FILE="dugite-native-$VERSION-$BUILD_HASH-macOS-$TARGET_ARCH.tar.gz"
  LZMA_FILE="dugite-native-$VERSION-$BUILD_HASH-macOS-$TARGET_ARCH.lzma"
elif [ "$TARGET_PLATFORM" == "win32" ]; then
  GZIP_FILE="dugite-native-$VERSION-$BUILD_HASH-windows-$TARGET_ARCH.tar.gz"
  LZMA_FILE="dugite-native-$VERSION-$BUILD_HASH-windows-$TARGET_ARCH.lzma"
else
  echo "Unable to package Git for platform $TARGET_PLATFORM"
  exit 1
fi

(
echo ""
PLATFORM=$(uname -s)
echo "Creating archives for $PLATFORM (${OSTYPE})..."
mkdir output
cd output || exit 1
if [ "$PLATFORM" == "Darwin" ]; then
  echo "Using bsdtar which has some different command flags"
  tar -czf "$GZIP_FILE" -C $DESTINATION .
  tar --lzma -cf "$LZMA_FILE" -C $DESTINATION .
elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]]; then
  echo "Using tar and 7z here because tar is unable to access lzma compression on Windows"
  tar -caf "$GZIP_FILE" -C $DESTINATION .
  # hacking around the fact that 7z refuses to write to LZMA files despite them
  # being the native format of 7z files
  NEW_LZMA_FILE="dugite-native-$VERSION-win32-test.7z"
  7z u -t7z "$NEW_LZMA_FILE" $DESTINATION/*
  mv "$NEW_LZMA_FILE" "$LZMA_FILE"
else
  echo "Using unix tar by default"
  tar -caf "$GZIP_FILE" -C $DESTINATION .
  tar -caf "$LZMA_FILE" -C $DESTINATION .
fi

GZIP_CHECKSUM=$(compute_checksum "$GZIP_FILE")
LZMA_CHECKSUM=$(compute_checksum "$LZMA_FILE")

echo "$GZIP_CHECKSUM" | tr -d '\n' > "${GZIP_FILE}.sha256"
echo "$LZMA_CHECKSUM" | tr -d '\n' > "${LZMA_FILE}.sha256"

GZIP_SIZE=$(du -h "$GZIP_FILE" | cut -f1)
LZMA_SIZE=$(du -h "$LZMA_FILE" | cut -f1)

echo "Packages created:"
echo "${GZIP_FILE} - ${GZIP_SIZE} - checksum: ${GZIP_CHECKSUM}"
echo "${LZMA_FILE} - ${LZMA_SIZE} - checksum: ${LZMA_CHECKSUM}"
)

set +eu
