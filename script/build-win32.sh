#!/bin/bash
#
# Repackaging Git for Windows and bundling Git LFS from upstream.
#

# i want to centralize this function but everything is terrible
# go read https://github.com/desktop/dugite-native/issues/38
computeChecksum() {
   if [ -z "$1" ] ; then
     # no parameter provided, fail hard
     exit 1
   fi

  path_to_sha256sum=$(which sha256sum)
  if [ -x "$path_to_sha256sum" ] ; then
    echo $(sha256sum $1 | awk '{print $1;}')
  else
    echo $(shasum -a 256 $1 | awk '{print $1;}')
  fi
}

DESTINATION=$1
mkdir -p $DESTINATION

if [ "$WIN_ARCH" -eq "64" ]; then MINGW_DIR="mingw64"; else MINGW_DIR="mingw32"; fi

echo "-- Downloading MinGit from $GIT_FOR_WINDOWS_URL"
GIT_FOR_WINDOWS_FILE=git-for-windows.zip
curl -sL -o $GIT_FOR_WINDOWS_FILE $GIT_FOR_WINDOWS_URL
COMPUTED_SHA256=$(computeChecksum $GIT_FOR_WINDOWS_FILE)
if [ "$COMPUTED_SHA256" = "$GIT_FOR_WINDOWS_CHECKSUM" ]; then
  echo "MinGit: checksums match"
  unzip -qq $GIT_FOR_WINDOWS_FILE -d $DESTINATION
else
  echo "MinGit: expected checksum $GIT_FOR_WINDOWS_CHECKSUM but got $COMPUTED_SHA256"
  echo "aborting..."
  exit 1
fi


if [[ "$GIT_LFS_VERSION" ]]; then
  # download Git LFS, verify its the right contents, and unpack it
  echo "-- Bundling Git LFS"
  GIT_LFS_FILE=git-lfs.zip
  if [ "$WIN_ARCH" -eq "64" ]; then GIT_LFS_ARCH="amd64"; else GIT_LFS_ARCH="386"; fi
  GIT_LFS_URL="https://github.com/git-lfs/git-lfs/releases/download/v${GIT_LFS_VERSION}/git-lfs-windows-${GIT_LFS_ARCH}-v${GIT_LFS_VERSION}.zip"
  echo "-- Downloading from $GIT_LFS_URL"
  curl -sL -o $GIT_LFS_FILE $GIT_LFS_URL
  COMPUTED_SHA256=$(computeChecksum $GIT_LFS_FILE)
  if [ "$COMPUTED_SHA256" = "$GIT_LFS_CHECKSUM" ]; then
    echo "Git LFS: checksums match"
    SUBFOLDER="$DESTINATION/$MINGW_DIR/libexec/git-core"
    unzip -j $GIT_LFS_FILE -x '*.md' -d $SUBFOLDER

    if [[ ! -f "$SUBFOLDER/git-lfs.exe" ]]; then
      echo "After extracting Git LFS the file was not found under /mingw64/libexec/git-core/"
      echo "aborting..."
      exit 1
    fi
  else
    echo "Git LFS: expected checksum $GIT_LFS_CHECKSUM and got $COMPUTED_SHA256"
    echo "aborting..."
    exit 1
  fi
else
  echo "-- Skipping Git LFS"
fi


SYSTEM_CONFIG="$DESTINATION/$MINGW_DIR/etc/gitconfig"

echo "-- Setting some system configuration values"
git config --file $SYSTEM_CONFIG core.symlinks "false"
git config --file $SYSTEM_CONFIG core.autocrlf "true"
git config --file $SYSTEM_CONFIG core.fscache "true"
git config --file $SYSTEM_CONFIG http.sslBackend "schannel"

# See https://github.com/desktop/desktop/issues/4817#issuecomment-393241303
# Even though it's not set openssl will auto-discover the one we ship because
# it sits in the right location already. So users manually switching
# http.sslBackend to openssl will still pick it up.
git config --file $SYSTEM_CONFIG --unset http.sslCAInfo

# Git for Windows 2.18.1 will support controlling how curl uses any certificate
# bundle - rather than just loading the bundle if http.useSSLCAInfo is set
# For the moment we want to favour using the OS certificate store unless the
# user has overriden this in their global configuration.
#
# details: https://github.com/dscho/git/blob/6152657e1a97c478df97d633c47469043b397519/Documentation/config.txt#L2135
git config --file $SYSTEM_CONFIG http.schannelUseSSLCAInfo "false"

# removing global gitattributes file
rm "$DESTINATION/$MINGW_DIR/etc/gitattributes"
echo "-- Removing global gitattributes which handles certain file extensions"

rm "$DESTINATION/$MINGW_DIR/bin/git-credential-store.exe"
rm "$DESTINATION/$MINGW_DIR/bin/git-credential-wincred.exe"
echo "-- Removing legacy credential helpers"


bold=$(tput bold)
normal=$(tput sgr0)

if [[ ! "$GIT_LFS_VERSION" ]]; then
  echo "${bold}warning:${normal} Skipped bundling of Git LFS (set GIT_LFS_VERSION to include it in the bundle)"
fi
