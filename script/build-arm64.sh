#!/bin/bash
#
# Building Git for ARM64 Linux and bundling Git LFS from upstream.
#

if [[ -z "${SOURCE}" ]]; then
  echo "Required environment variable SOURCE was not set"
  exit 1
fi

if [[ -z "${DESTINATION}" ]]; then
  echo "Required environment variable DESTINATION was not set"
  exit 1
fi

if [[ -z "${CURL_INSTALL_DIR}" ]]; then
  echo "Required environment variable CURL_INSTALL_DIR was not set"
  exit 1
fi

if [[ -z "${BASEDIR}" ]]; then
  echo "Required environment variable BASEDIR was not set"
  exit 1
fi


CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# shellcheck source=script/compute-checksum.sh
source "$CURRENT_DIR/compute-checksum.sh"
# shellcheck source=script/check-static-linking.sh
source "$CURRENT_DIR/check-static-linking.sh"

mkdir -p "$DESTINATION"

docker run --rm --privileged multiarch/qemu-user-static:register --reset
docker run -it \
--mount type=bind,source="$BASEDIR",target="$BASEDIR" \
--mount type=bind,source="$DESTINATION",target="$DESTINATION" \
-e "SOURCE=$SOURCE" \
-e "DESTINATION=$DESTINATION" \
-e "CURL_INSTALL_DIR=$CURL_INSTALL_DIR" \
-w="$BASEDIR" \
--rm shiftkey/dugite-native:arm64-jessie-git-with-curl sh "$BASEDIR/script/build-arm64-git.sh"

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


(
# download CA bundle and write straight to temp folder
# for more information: https://curl.haxx.se/docs/caextract.html
echo "-- Adding CA bundle"
cd "$DESTINATION" || exit 1
mkdir -p ssl
curl -sL -o ssl/cacert.pem https://curl.haxx.se/ca/cacert.pem
)

if [[ ! -f "$DESTINATION/ssl/cacert.pem" ]]; then
  echo "-- Skipped bundling of CA certificates (failed to download them)"
fi

echo "-- Verifying environment"
docker run -it \
  --mount type=bind,source="$BASEDIR",target="$BASEDIR" \
  --mount type=bind,source="$DESTINATION",target="$DESTINATION" \
  -e "DESTINATION=$DESTINATION" \
  -w="$BASEDIR" \
  --rm shiftkey/dugite-native:arm64-jessie-git-with-curl sh "$BASEDIR/script/verify-arm64-git.sh"

echo "-- Static linking research"
check_static_linking "$DESTINATION"
