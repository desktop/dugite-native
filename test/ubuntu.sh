#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ROOT="$DIR/.."
SOURCE="$ROOT/git"
DESTINATION="$ROOT/build/git"

GIT_LFS_URL=https://github.com/git-lfs/git-lfs/releases/download/v2.2.1/git-lfs-linux-amd64-2.2.1.tar.gz \
GIT_LFS_CHECKSUM=95bcdab9897338fd923ad3a792010d6e817114e8c3b444e1e245889b6cd68888 \
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