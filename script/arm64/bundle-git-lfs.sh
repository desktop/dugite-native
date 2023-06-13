#!/bin/bash -e

if [[ -z "${DESTINATION}" ]]; then
  echo "Required environment variable DESTINATION was not set"
  exit 1
fi

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# shellcheck source=script/compute-checksum.sh
source "$CURRENT_DIR/../compute-checksum.sh"

if [[ "$GIT_LFS_VERSION" ]]; then
  echo "-- Bundling Git LFS"
  GIT_LFS_FILE=git-lfs.tar.gz
  GIT_LFS_URL="https://github.com/git-lfs/git-lfs/releases/download/v${GIT_LFS_VERSION}/git-lfs-linux-arm64-v${GIT_LFS_VERSION}.tar.gz"
  echo "-- Downloading from $GIT_LFS_URL"
  curl -sL -o $GIT_LFS_FILE "$GIT_LFS_URL"
  COMPUTED_SHA256=$(compute_checksum $GIT_LFS_FILE)
  if [ "$COMPUTED_SHA256" = "$GIT_LFS_CHECKSUM" ]; then
    echo "Git LFS: checksums match"
    SUBFOLDER="$DESTINATION/libexec/git-core"
    tar -xvf $GIT_LFS_FILE -C "$SUBFOLDER" --exclude='*.sh' --exclude="*.md"

    if [[ ! -f "$SUBFOLDER/git-lfs" ]]; then
      echo "After extracting Git LFS the file was not found under libexec/git-core/"
      echo "aborting..."
      exit 1
    fi
  else
    echo "Git LFS: expected checksum $GIT_LFS_CHECKSUM but got $COMPUTED_SHA256"
    echo "aborting..."
    exit 1
  fi
else
  echo "-- Skipped bundling Git LFS (set GIT_LFS_VERSION to include it in the bundle)"
fi
