#!/bin/bash -e
#
# Compiling Git for macOS and bundling Git LFS from upstream.
#

if [[ -z "${SOURCE}" ]]; then
  echo "Required environment variable SOURCE was not set"
  exit 1
fi

if [[ -z "${DESTINATION}" ]]; then
  echo "Required environment variable DESTINATION was not set"
  exit 1
fi

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=script/compute-checksum.sh
source "$CURRENT_DIR/compute-checksum.sh"

echo "-- Building git at $SOURCE to $DESTINATION"

(
  cd "$SOURCE" || exit 1
  make clean
  DESTDIR="$DESTINATION" make strip install prefix=/ \
    NO_PERL=1 \
    NO_TCLTK=1 \
    NO_GETTEXT=1 \
    NO_DARWIN_PORTS=1 \
    NO_INSTALL_HARDLINKS=1 \
    MACOSX_DEPLOYMENT_TARGET=10.10
)

if [[ "$GIT_LFS_VERSION" ]]; then
  echo "-- Bundling Git LFS"
  git clone -b "v$GIT_LFS_VERSION" "http://github.com/git-lfs/git-lfs"
  (
    cd git-lfs
    make CGO_CFLAGS="-mmacosx-version-min=10.10" CGO_LDFLAGS="-mmacosx-version-min=10.10" BUILTIN_LD_FLAGS="-linkmode external"
  )
  if test -f "git-lfs/bin/git-lfs"; then
    cp "git-lfs/bin/git-lfs" "$DESTINATION/libexec/git-core/"
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
