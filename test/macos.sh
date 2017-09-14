#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ROOT="$DIR/.."
SOURCE="$ROOT/git"
DESTINATION="$ROOT/build/git"

GIT_LFS_URL=https://github.com/git-lfs/git-lfs/releases/download/v2.3.0/git-lfs-darwin-amd64-2.3.0.tar.gz \
GIT_LFS_CHECKSUM=37d588897194fe959d8d39bae1f057d486be53e0f2f7252abeacfd8aa31da9ee \
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
