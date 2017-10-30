#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ROOT="$DIR/.."
SOURCE="$ROOT/git"
DESTINATION="$ROOT/build/git"

GIT_FOR_WINDOWS_URL=https://github.com/git-for-windows/git/releases/download/v2.15.0.windows.1/MinGit-2.15.0-64-bit.zip \
GIT_FOR_WINDOWS_CHECKSUM=fb5aad5e18a9f9f86e33a94e6fc0f0d88d0defd227e43f10316d871f2123c0d4 \
GIT_LFS_URL=https://github.com/git-lfs/git-lfs/releases/download/v2.3.4/git-lfs-windows-amd64-2.3.4.zip \
GIT_LFS_CHECKSUM=18c47fd2806659e81a40fbd6f6b0598ea1802635ce04fb2317d75973450a3fe5 \
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