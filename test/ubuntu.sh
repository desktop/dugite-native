#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ROOT="$DIR/.."
SOURCE="$ROOT/git"
DESTINATION="$ROOT/build/git"

GIT_LFS_URL=https://github.com/git-lfs/git-lfs/releases/download/v2.3.4/git-lfs-linux-amd64-2.3.4.tar.gz \
GIT_LFS_CHECKSUM=6755e109a85ffd9a03aacc629ea4ab1cbb8e7d83e41bd1880bf44b41927f4cfe \
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