#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ROOT="$DIR/.."
SOURCE="$ROOT/git"
DESTINATION="$ROOT/build/git"

GIT_FOR_WINDOWS_URL=https://github.com/git-for-windows/git/releases/download/v2.14.2.windows.1/MinGit-2.14.2-64-bit.zip \
GIT_FOR_WINDOWS_CHECKSUM=9638733b8d749c43d59c34a714d582b2352356ee7d13c4acf919c18f307387f5 \
GIT_LFS_URL=https://github.com/git-lfs/git-lfs/releases/download/v2.3.1/git-lfs-windows-amd64-2.3.1.zip \
GIT_LFS_CHECKSUM=61fa2e8122b374b1d7a87f59ed8d3a0d08b4c8ab6cb2d50b4bc61283d91bbf50 \
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