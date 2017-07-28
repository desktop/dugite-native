#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ROOT="$DIR/.."
SOURCE="$ROOT/git"
DESTINATION="$ROOT/build/git"

GIT_LFS_URL=https://github.com/git-lfs/git-lfs/releases/download/v2.2.1/git-lfs-darwin-amd64-2.2.1.tar.gz \
GIT_LFS_CHECKSUM=1da31fa2cc75fe56486cbaf371ca4d233889a8105cc9d9435284a0a7a3c87bec \
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