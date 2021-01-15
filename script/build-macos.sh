#!/bin/bash -e
#
# Compiling Git for macOS and bundling Git LFS from upstream.
#

set -eu -o pipefail

MACOSX_BUILD_VERSION="10.9"

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

(
  cd "$SOURCE" || exit 1
  make clean
  # On the GitHub Actions macOS runners the curl-config command resolves to
  # a homebrew-installed version of curl which ends up providing us with a
  # library search path (-L/usr/local/Cellar/curl/7.74.0/lib) instead of
  # simply `-lcurl`. This causes problems when the git binaries are used on
  # systems that don't have the homebrew version of curl. We want to use the
  # system-provided curl.
  #
  # Specifically we saw this be a problem when the git-remote-https binary
  # was signed during the bundling process of GitHub Desktop and attempts to
  # execute it would trigger the following error
  #
  # dyld: Library not loaded: /usr/local/opt/curl/lib/libcurl.4.dylib
  # Referenced from: /Applications/GitHub Desktop.app/[...]/git-remote-https
  # Reason: image not found
  #
  # For this reason we set CURL_CONFIG to the system version explicitly here.
  DESTDIR="$DESTINATION" make strip install prefix=/ \
    CURL_CONFIG=/usr/bin/curl-config \
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
    make CGO_CFLAGS="-mmacosx-version-min=$MACOSX_BUILD_VERSION" CGO_LDFLAGS="-mmacosx-version-min=$MACOSX_BUILD_VERSION" BUILTIN_LD_FLAGS="-linkmode external"
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
rm "$DESTINATION/libexec/git-core/git-remote-testsvn"
rm "$DESTINATION/libexec/git-core/git-p4"

set +eu
