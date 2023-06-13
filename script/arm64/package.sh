#!/bin/bash -e
#
# Script for packaging artefacts into gzipped archive.
# Build scripts should handle platform-specific differences, so this
# script works off the assumption that everything at $DESTINATION is
# intended to be part of the archive.
#

if [[ -z "${DESTINATION}" ]]; then
  echo "Required environment variable DESTINATION was not set"
  exit 1
fi

VERSION=$(
  cd "$SOURCE" || exit 1
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

GZIP_FILE="dugite-native-$VERSION-$BUILD_HASH-arm64.tar.gz"
LZMA_FILE="dugite-native-$VERSION-$BUILD_HASH-arm64.lzma"

(
echo ""
echo "Creating archives..."
mkdir output
cd output
if [ "$(uname -s)" == "Darwin" ]; then
  tar -czf "$GZIP_FILE" -C "$DESTINATION" .
  tar --lzma -cf "$LZMA_FILE" -C "$DESTINATION" .
else
  tar -caf "$GZIP_FILE" -C "$DESTINATION" .
  tar -caf "$LZMA_FILE" -C "$DESTINATION" .
fi

GZIP_CHECKSUM=$(shasum -a 256 "$GZIP_FILE" | awk '{print $1;}')
LZMA_CHECKSUM=$(shasum -a 256 "$LZMA_FILE" | awk '{print $1;}')

echo "$GZIP_CHECKSUM" | tr -d '\n' > "${GZIP_FILE}.sha256"
echo "$LZMA_CHECKSUM" | tr -d '\n' > "${LZMA_FILE}.sha256"

GZIP_SIZE=$(du -h "$GZIP_FILE" | cut -f1)
LZMA_SIZE=$(du -h "$LZMA_FILE" | cut -f1)

echo "Packages created:"
echo "${GZIP_FILE} - ${GZIP_SIZE} - checksum: ${GZIP_CHECKSUM}"
echo "${LZMA_FILE} - ${LZMA_SIZE} - checksum: ${LZMA_CHECKSUM}"
)
