#!/bin/bash
#
# Repackaging Git for Windows and bundling Git LFS from upstream.
#

DESTINATION=$1
mkdir -p $DESTINATION

# download Git for Windows, verify its the right contents, and unpack it
GIT_FOR_WINDOWS_FILE=git-for-windows.zip
curl -sL -o $GIT_FOR_WINDOWS_FILE $GIT_FOR_WINDOWS_URL
if [ "$APPVEYOR" == "True" ]; then
  COMPUTED_SHA256=$(sha256sum $GIT_FOR_WINDOWS_FILE | awk '{print $1;}')
else
  COMPUTED_SHA256=$(shasum -a 256 $GIT_FOR_WINDOWS_FILE | awk '{print $1;}')
fi

if [ "$COMPUTED_SHA256" = "$GIT_FOR_WINDOWS_CHECKSUM" ]; then
  echo "Git for Windows: checksums match"
  unzip -qq $GIT_FOR_WINDOWS_FILE -d $DESTINATION
else
  echo "Git for Windows: expected checksum $GIT_FOR_WINDOWS_CHECKSUM but got $COMPUTED_SHA256"
  echo "aborting..."
  exit 1
fi

# download Git LFS, verify its the right contents, and unpack it
GIT_LFS_FILE=git-lfs.zip
curl -sL -o $GIT_LFS_FILE $GIT_LFS_URL
if [ "$APPVEYOR" == "True" ]; then
  COMPUTED_SHA256=$(sha256sum $GIT_LFS_FILE | awk '{print $1;}')
else
  COMPUTED_SHA256=$(shasum -a 256 $GIT_LFS_FILE | awk '{print $1;}')
fi
if [ "$COMPUTED_SHA256" = "$GIT_LFS_CHECKSUM" ]; then
  echo "Git LFS: checksums match"
  SUBFOLDER="$DESTINATION/mingw64/libexec/git-core/"
  unzip -qq -j $GIT_LFS_FILE -x '*.md' -d $SUBFOLDER
else
  echo "Git LFS: expected checksum $GIT_LFS_CHECKSUM and got $COMPUTED_SHA256"
  echo "aborting..."
  exit 1
fi

# replace OpenSSL curl with the WinSSL variant
# this was recently incorporated into MinGit, so let's just move the file over and cleanup
ORIGINAL_CURL_LIBRARY="$DESTINATION/mingw64/bin/libcurl-4.dll"
WINSSL_CURL_LIBRARY="$DESTINATION/mingw64/bin/curl-winssl/libcurl-4.dll"
mv $WINSSL_CURL_LIBRARY $ORIGINAL_CURL_LIBRARY
rm -rf "$DESTINATION/mingw64/bin/curl-winssl/"

if [ "$APPVEYOR" == "True" ]; then
  # find the version of libcurl that was bundled
  PACKAGE_ENTRY=$(grep -o 'curl [0-9].[0-9]\{2\}.[0-9]-[0-9]' /tmp/build/git/etc/package-versions.txt)
  PACKAGE_VERSION=${PACKAGE_ENTRY/curl /}

  echo "Using curl version version $PACKAGE_VERSION"
  CURL_FILE="curl.tar.xz"
  CURL_BINARY_DOWNLOAD="https://dl.bintray.com/git-for-windows/pacman/x86_64/mingw-w64-x86_64-curl-$PACKAGE_VERSION-any.pkg.tar.xz"
  curl -sL -o $CURL_FILE $CURL_BINARY_DOWNLOAD

  # extract just the executable to test alongside our libcurl-4.dll change
  7z e $CURL_FILE -aoa -ooutput > nul
  7z e output/curl.tar -aoa -ooutput *.exe -r > nul
  cp ./output/curl.exe "$DESTINATION/mingw64/bin/"
  rm -rf ./output

  $DESTINATION/mingw64/bin/curl.exe --version | grep 'WinSSL'
  EXIT_CODE=$?
  rm $DESTINATION/mingw64/bin/curl.exe

  if [ "$EXIT_CODE" == "1" ]; then
    echo "cURL not able to resolve WinSSL dependency. Failing the build..."
    exit 1
  else
    echo "Verified cURL dependency is using WinSSL"
  fi
fi