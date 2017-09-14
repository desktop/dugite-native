#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ROOT="$DIR/.."
SOURCE="$ROOT/git"
DESTINATION="$ROOT/build/git"

GIT_FOR_WINDOWS_URL=https://github.com/git-for-windows/git/releases/download/v2.14.1.windows.1/MinGit-2.14.1-64-bit.zip \
GIT_FOR_WINDOWS_CHECKSUM=65c12e4959b8874187b68ec37e532fe7fc526e10f6f0f29e699fa1d2449e7d92 \
GIT_LFS_URL=https://github.com/git-lfs/git-lfs/releases/download/v2.3.0/git-lfs-windows-amd64-2.3.0.zip \
GIT_LFS_CHECKSUM=0be7e8755e1c2d9a598f369ce1db63fd7f2a8985d1c078cb815a3e50961066c2 \
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
