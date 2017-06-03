#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ROOT="$DIR/.."

GIT_LFS_URL=https://github.com/git-lfs/git-lfs/releases/download/v2.1.0/git-lfs-linux-amd64-2.1.0.tar.gz \
GIT_LFS_CHECKSUM=0260d1908b097dcd703ef6cf83d9c32c1a418325d29b063bf03a165e3dd8e364 \
. "$ROOT/script/build-ubuntu.sh" "$ROOT/git" "$ROOT/build/git/"