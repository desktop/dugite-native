#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ROOT="$DIR/.."
SOURCE="$ROOT/git"
DESTINATION="$ROOT/build/git"

GIT_LFS_URL=https://github.com/git-lfs/git-lfs/releases/download/v2.3.1/git-lfs-linux-amd64-2.3.1.tar.gz \
GIT_LFS_CHECKSUM=6ea96cf57fba70c425c470c248d0f770f86d3f3ccf5bc3ef6c46fb47c80816a1 \
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