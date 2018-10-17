#!/bin/bash
#
# Compiling Git for Linux and bundling Git LFS from upstream.
#

SOURCE=$1
DESTINATION=$2
BASEDIR=$3

mkdir -p $DESTINATION

docker run --rm --privileged multiarch/qemu-user-static:register --reset
docker run -it \
--mount type=bind,source=$BASEDIR,target=$BASEDIR \
--mount type=bind,source=$DESTINATION,target=$DESTINATION \
-e "SOURCE=$SOURCE" \
-e "DESTINATION=$DESTINATION" \
-w=$BASEDIR \
--rm multiarch/debian-debootstrap:arm64-jessie sh $BASEDIR/script/build-arm64-git.sh
cd - > /dev/null


if [[ "$GIT_LFS_VERSION" ]]; then
  echo "-- Building Git LFS"
  go get github.com/git-lfs/git-lfs
  GOPATH=`go env GOPATH`
  cd $GOPATH/src/github.com/git-lfs/git-lfs
  git checkout "v${GIT_LFS_VERSION}"
  # Make the 'mangen' target first, without setting GOOS/GOARCH.
  make mangen
  make GOARCH=arm64 GOOS=linux
  GIT_LFS_OUTPUT_DIR=$GOPATH/src/github.com/git-lfs/git-lfs/bin/

  echo "-- Verifying built Git LFS"
  docker run -it \
   --mount type=bind,source=$GIT_LFS_OUTPUT_DIR,target=$GIT_LFS_OUTPUT_DIR \
   -w=$BASEDIR \
   --rm multiarch/debian-debootstrap:arm64-jessie $GIT_LFS_OUTPUT_DIR/git-lfs --version

  echo "-- Bundling Git LFS"
  GIT_LFS_FILE=$GIT_LFS_OUTPUT_DIR/git-lfs
  SUBFOLDER="$DESTINATION/libexec/git-core"
  cp $GIT_LFS_FILE $SUBFOLDER
else
  echo "-- Skipping Git LFS"
fi


# download CA bundle and write straight to temp folder
# for more information: https://curl.haxx.se/docs/caextract.html
echo "-- Adding CA bundle"
cd $DESTINATION
mkdir -p ssl
curl -sL -o ssl/cacert.pem https://curl.haxx.se/ca/cacert.pem
cd - > /dev/null


checkStaticLinking() {
  if [ -z "$1" ] ; then
    # no parameter provided, fail hard
    exit 1
  fi

  # ermagherd there's two whitespace characters between 'LSB' and 'executable'
  # when running this on Travis - why is everything so terrible?
  if file $1 | grep -q 'ELF 64-bit LSB'; then
    if readelf -d $1 | grep -q 'Shared library'; then
      echo "File: $file"
      # this is done twice rather than storing in a bash variable because
      # it's easier than trying to preserve the line endings
      readelf -d $1 | grep 'Shared library'
    fi
  fi
}

echo "-- Static linking research"
cd "$DESTINATION"
# check all files for ELF exectuables
find . -type f -print0 | while read -d $'\0' file
do
  checkStaticLinking $file
done
cd - > /dev/null


bold=$(tput bold)
normal=$(tput sgr0)

if [[ ! -f "$SOURCE/ssl/cacert.pem" ]]; then
  echo "${bold}warning:${normal} Skipped bundling of CA certificates (failed to download them)"
fi

if [[ ! "$GIT_LFS_VERSION" ]]; then
  echo "${bold}warning:${normal} Skipped bundling of Git LFS (set GIT_LFS_VERSION to include it in the bundle)"
fi
