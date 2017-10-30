#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ROOT="$DIR/.."
SOURCE="$ROOT/git"
DESTINATION="$ROOT/build/git"

GIT_LFS_URL=https://github.com/git-lfs/git-lfs/releases/download/v2.3.4/git-lfs-darwin-amd64-2.3.4.tar.gz \
GIT_LFS_CHECKSUM=b16d4b7469b1fa34e0e27bedb1b77cc425b8d7903264854e5f18b0bc73576edb \
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