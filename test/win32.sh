#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ROOT="$DIR/.."
SOURCE="$ROOT/git"
DESTINATION="$ROOT/build/git"

GIT_FOR_WINDOWS_URL=https://github.com/git-for-windows/git/releases/download/v2.13.0.windows.1/MinGit-2.13.0-64-bit.zip \
GIT_FOR_WINDOWS_CHECKSUM=20acda973eca1df056ad08bec6e05c3136f40a1b90e2a290260dfc36e9c2c800 \
GIT_LFS_URL=https://github.com/git-lfs/git-lfs/releases/download/v2.1.0/git-lfs-windows-amd64-2.1.0.zip \
GIT_LFS_CHECKSUM=a40adc489a99d1b7809aab89fa78b6dee2399af6542e4b9faae552a7a248c1ce \
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