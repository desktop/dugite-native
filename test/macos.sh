#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ROOT="$DIR/.."
SOURCE="$ROOT/git"
DESTINATION="$ROOT/build/git"

GIT_LFS_URL=https://github.com/git-lfs/git-lfs/releases/download/v2.1.0/git-lfs-darwin-amd64-2.1.0.tar.gz \
GIT_LFS_CHECKSUM=e7c841a4a7d6e5f319c21f7836f6cbad1f1abe93c3dc6f532903c9b8cf589b3c \
. "$ROOT/script/build-macos.sh" $SOURCE $DESTINATION

FILE="dugite-native-$VERSION-macos-test.tar.gz"

tar -czf $FILE -C $DESTINATION .

echo "Archive contents:"
cd $DESTINATION
du -ah $DESTINATION
cd - > /dev/null

echo ""
SIZE=$(du -h $FILE | cut -f1)
echo "Package size: ${SIZE}"