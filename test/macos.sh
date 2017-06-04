#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ROOT="$DIR/.."
SOURCE="$ROOT/git"
DESTINATION="$ROOT/build/git"

GIT_LFS_URL=https://github.com/git-lfs/git-lfs/releases/download/v2.1.1/git-lfs-darwin-amd64-2.1.1.tar.gz \
GIT_LFS_CHECKSUM=acefceb077d77d69e35f0017de91b8ea42cf980315226446b5c1dcafd9328e53 \
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