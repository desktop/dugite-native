#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ROOT="$DIR/.."
SOURCE="$ROOT/git"
DESTINATION="$ROOT/build/git"

GIT_LFS_URL=https://github.com/git-lfs/git-lfs/releases/download/v2.1.1/git-lfs-linux-amd64-2.1.1.tar.gz \
GIT_LFS_CHECKSUM=ee41f7aa2e860ab2abf065bef71e7344b9777c5da25cde8a36891e4d8eb2bbdf \
. "$ROOT/script/build-ubuntu.sh" $SOURCE $DESTINATION

FILE="dugite-native-$VERSION-ubuntu-test.tar.gz"

tar -czf $FILE -C $DESTINATION .

echo "Archive contents:"
cd $DESTINATION
du -ah $DESTINATION
cd - > /dev/null

echo ""
SIZE=$(du -h $FILE | cut -f1)
echo "Package size: ${SIZE}"