#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ROOT="$DIR/.."
SOURCE="$ROOT/git"
DESTINATION="$ROOT/build/git"

GIT_FOR_WINDOWS_URL=https://github.com/git-for-windows/git/releases/download/v2.13.3.windows.1/MinGit-2.13.3-64-bit.zip \
GIT_FOR_WINDOWS_CHECKSUM=97063e2139cac40f3c8f547b85f031765062581101d69ad468188c9de0b1dca3 \
GIT_LFS_URL=https://github.com/git-lfs/git-lfs/releases/download/v2.2.1/git-lfs-windows-amd64-2.2.1.zip \
GIT_LFS_CHECKSUM=35e120c03061c7a3de8348b970da2278a2e0a865d4c67179801266a2d7674d2d \
. "$ROOT/script/build-win32.sh" $SOURCE $DESTINATION

FILE="dugite-native-$VERSION-win32-test.tar.gz"

tar -czf $FILE -C $DESTINATION .

echo "Archive contents:"
cd $DESTINATION
du -ah $DESTINATION
cd - > /dev/null

echo ""
SIZE=$(du -h $FILE | cut -f1)
echo "Package size: ${SIZE}"