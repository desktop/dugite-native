#!/bin/bash -e
#
# Compiling Git for macOS and bundling Git LFS from upstream.
#

set -eu -o pipefail

MACOSX_BUILD_VERSION="10.15"

if [ "$TARGET_ARCH" = "x64" ]; then
  HOST_CPU=x86_64
  TARGET_CFLAGS="-target x86_64-apple-darwin"
  GOARCH=amd64
  DEPENDENCY_ARCH="amd64"
else
  HOST_CPU=arm64
  TARGET_CFLAGS="-target arm64-apple-darwin"
  GOARCH=arm64
  DEPENDENCY_ARCH="arm64"
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
GIT_LFS_CHECKSUM="$(jq --raw-output ".\"git-lfs\".files[] | select(.arch == \"$DEPENDENCY_ARCH\" and .platform == \"darwin\") | .checksum" dependencies.json)"
GIT_LFS_FILENAME="$(jq --raw-output ".\"git-lfs\".files[] | select(.arch == \"$DEPENDENCY_ARCH\" and .platform == \"darwin\") | .name" dependencies.json)"

# shellcheck source=script/compute-checksum.sh
source "$CURRENT_DIR/compute-checksum.sh"
# shellcheck source=script/verify-lfs-contents.sh
source "$CURRENT_DIR/verify-lfs-contents.sh"

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
  #
  # HACK: There is no way of adding additional CFLAGS without running the
  # configure script. However the Makefile prepends some developer CFLAGS that
  # we could use to select the right target CPU to cross-compile git.
  DESTDIR="$DESTINATION" make strip install prefix=/ \
    DEVELOPER_CFLAGS="$TARGET_CFLAGS" \
    HOST_CPU="$HOST_CPU" \
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
  GIT_LFS_FILE=git-lfs.tar.gz
  GIT_LFS_URL="https://github.com/git-lfs/git-lfs/releases/download/v${GIT_LFS_VERSION}/${GIT_LFS_FILENAME}"
  echo "-- Downloading from $GIT_LFS_URL"
  curl -sL -o $GIT_LFS_FILE "$GIT_LFS_URL"
  COMPUTED_SHA256=$(compute_checksum $GIT_LFS_FILE)
  if [ "$COMPUTED_SHA256" = "$GIT_LFS_CHECKSUM" ]; then
    echo "Git LFS: checksums match"
    SUBFOLDER="$DESTINATION/libexec/git-core"

    verify_lfs_contents "$GIT_LFS_FILE"

    unzip -j $GIT_LFS_FILE -d "$SUBFOLDER" "*/git-lfs"

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

GCM_VERSION="$(jq --raw-output '.["git-credential-manager"].version[1:]' dependencies.json)"
GCM_CHECKSUM="$(jq --raw-output ".\"git-credential-manager\".files[] | select(.arch == \"$GOARCH\" and .platform == \"darwin\") | .checksum" dependencies.json)"
GCM_URL="$(jq --raw-output ".\"git-credential-manager\".files[] | select(.arch == \"$GOARCH\" and .platform == \"darwin\") | .url" dependencies.json)"

if [[ "$GCM_VERSION" && "$GCM_URL" ]]; then
  echo "-- Bundling GCM"
  GCM_FILE=git-credential-manager.tar.gz
  echo "-- Downloading from $GCM_URL"
  curl -sL -o $GCM_FILE "$GCM_URL"
  COMPUTED_SHA256=$(compute_checksum $GCM_FILE)
  if [ "$COMPUTED_SHA256" = "$GCM_CHECKSUM" ]; then
    echo "GCM: checksums match"
    SUBFOLDER="$DESTINATION/libexec/git-core"
    tar -xvkf $GCM_FILE -C "$SUBFOLDER"

    if [[ ! -f "$SUBFOLDER/git-credential-manager" ]]; then
      echo "After extracting GCM the file was not found under libexec/git-core/"
      echo "aborting..."
      exit 1
    fi
    chmod +x "$SUBFOLDER/git-credential-manager"
  else
    echo "GCM: expected checksum $GCM_CHECKSUM but got $COMPUTED_SHA256"
    echo "aborting..."
    exit 1
  fi
else
  if [ -z "$GCM_URL" ]; then
    echo "-- No download URL for GCM on macOS/$GOARCH, skipping bundling"
  else
    echo "-- Skipped bundling GCM (set GCM_VERSION to include it in the bundle)"
  fi
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

echo "-- Copying dugite custom system gitconfig"
mkdir "$DESTINATION/etc"
cp "$CURRENT_DIR/../resources/posix.gitconfig" "$DESTINATION/etc/gitconfig"

set +eu
