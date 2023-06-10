#!/bin/bash -e
#
# Compiling Git for macOS and bundling Git LFS from upstream.
#

set -eu -o pipefail

MACOSX_BUILD_VERSION="10.9"

if [ "$TARGET_ARCH" = "x64" ]; then
  HOST_CPU=x86_64
  TARGET_CFLAGS="-target x86_64-apple-darwin"
  GOARCH=amd64
else
  HOST_CPU=arm64
  TARGET_CFLAGS="-target arm64-apple-darwin"
  GOARCH=arm64
fi

if [[ -z "${SOURCE}" ]]; then
  echo "Required environment variable SOURCE was not set"
  exit 1
fi

if [[ -z "${DESTINATION}" ]]; then
  echo "Required environment variable DESTINATION was not set"
  exit 1
fi

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GIT_LFS_VERSION="$(jq --raw-output '.["git-lfs"].version[1:]' dependencies.json)"
# shellcheck source=script/compute-checksum.sh
source "$CURRENT_DIR/compute-checksum.sh"

echo "-- Building git at $SOURCE to $DESTINATION"

cd $SOURCE
make clean
DESTDIR="$DESTINATION" make install prefix=/ \
    NO_PERL=1 \
    NO_TCLTK=1 \
    NO_GETTEXT=1 \
    NO_DARWIN_PORTS=1 \
    NO_INSTALL_HARDLINKS=1 \
    MACOSX_DEPLOYMENT_TARGET=$MACOSX_BUILD_VERSION
)

if [[ "$GIT_LFS_VERSION" ]]; then
  echo "-- Bundling Git LFS"
  # build steps from https://github.com/git-lfs/git-lfs/wiki/Installation#source
  # git tags for git-lfs are the version number prefixed with "v"
  git clone -b "v$GIT_LFS_VERSION" "https://github.com/git-lfs/git-lfs"
  (
    cd git-lfs

    # HACK: When cross-compiling, there seems to be an issue when git-lfs attempts
    # to generate the manpage contents, and it seems that preffixing that command
    # with `GOARCH=` to use the host architecture fixes the issue.
    # This hack can be removed once the issue is fixed via the PR
    # https://github.com/git-lfs/git-lfs/pull/4492 or some other solution.
    GO_GENERATE_STRING="\$(GO) generate github.com\/git-lfs\/git-lfs\/commands"
    sed -i -e "s/$GO_GENERATE_STRING/GOARCH= $GO_GENERATE_STRING/" Makefile

    make GOARCH="$GOARCH" CGO_CFLAGS="-mmacosx-version-min=$MACOSX_BUILD_VERSION" CGO_LDFLAGS="-mmacosx-version-min=$MACOSX_BUILD_VERSION" BUILTIN_LD_FLAGS="-linkmode external"
  )
  GIT_LFS_BINARY_PATH="git-lfs/bin/git-lfs"
  if test -f "$GIT_LFS_BINARY_PATH"; then
    cp "$GIT_LFS_BINARY_PATH" "$DESTINATION/libexec/git-core/"
  else
    echo "The git-lfs binary is missing, the build must have failed"
    echo "aborting..."
    exit 1
  fi
else
  echo "-- Skipped bundling Git LFS (set GIT_LFS_VERSION to include it in the bundle)"
fi

echo "-- Removing server-side programs"
rm "$DESTINATION/bin/git-cvsserver"
rm "$DESTINATION/bin/git-receive-pack"
rm "$DESTINATION/bin/git-upload-archive"
rm "$DESTINATION/bin/git-upload-pack"
rm "$DESTINATION/bin/git-shell"

echo "-- Removing unsupported features"
rm "$DESTINATION/libexec/git-core/git-svn"
rm "$DESTINATION/libexec/git-core/git-p4"

set +eu
