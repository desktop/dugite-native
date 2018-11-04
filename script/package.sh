#!/bin/bash -e
#
# Script for packaging artefacts into gzipped archive.
# Build scripts should handle platform-specific differences, so this
# script works off the assumption that everything at $DESTINATION is
# intended to be part of the archive.

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
  GZIP_FILE="dugite-native-$VERSION-$BUILD_HASH-ubuntu.tar.gz"
  LZMA_FILE="dugite-native-$VERSION-$BUILD_HASH-ubuntu.lzma"
elif [ "$TARGET_PLATFORM" == "macOS" ]; then
  GZIP_FILE="dugite-native-$VERSION-$BUILD_HASH-macOS.tar.gz"
  LZMA_FILE="dugite-native-$VERSION-$BUILD_HASH-macOS.lzma"
elif [ "$TARGET_PLATFORM" == "win32" ]; then
  if [ "$WIN_ARCH" -eq "64" ]; then ARCH="x64"; else ARCH="x86"; fi
  GZIP_FILE="dugite-native-$VERSION-$BUILD_HASH-windows-$ARCH.tar.gz"
  LZMA_FILE="dugite-native-$VERSION-$BUILD_HASH-windows-$ARCH.lzma"
elif [ "$TARGET_PLATFORM" == "arm64" ]; then
  GZIP_FILE="dugite-native-$VERSION-$BUILD_HASH-arm64.tar.gz"
  LZMA_FILE="dugite-native-$VERSION-$BUILD_HASH-arm64.lzma"
else
  echo "Unable to package Git for platform $TARGET_PLATFORM"
  exit 1
fi

(
echo ""
echo "Creating archives for platform ${OSTYPE}..."
mkdir output
cd output || exit 1
if [[ "$OSTYPE" == "darwin*" ]]; then
  echo "Using bsdtar which has some different command flags"
  tar -czf "$GZIP_FILE" -C $DESTINATION .
  tar --lzma -cf "$LZMA_FILE" -C $DESTINATION .
elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]]; then
  echo "Using 7z to generate the lzma file because the host doesn't have a working environment for tar to do this natively"
  tar -caf "$GZIP_FILE" -C $DESTINATION .
  7z --help
  exit 1
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