#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ROOT="$DIR/.."
SOURCE="$ROOT/git"
DESTINATION="$ROOT/build/git"

GIT_LFS_URL=https://github.com/git-lfs/git-lfs/releases/download/v2.3.0/git-lfs-linux-amd64-2.3.0.tar.gz \
GIT_LFS_CHECKSUM=5913ed4d023efe30a3f8f536db7cd97c7b76ba68b189baef8428b1d71d82f2f4 \
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
