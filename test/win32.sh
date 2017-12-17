#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ROOT="$DIR/.."
SOURCE="$ROOT/git"
DESTINATION="$ROOT/build/git"

GIT_FOR_WINDOWS_URL=https://github.com/git-for-windows/git/releases/download/v2.15.1.windows.1/MinGit-2.15.1-64-bit.zip \
GIT_FOR_WINDOWS_CHECKSUM=5e38d13241b0742e6673bc5116ac82e851dd1fad01c660c943017f4549b6afea \
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