#!/bin/bash
#
# Compiling Git for macOS and bundling Git LFS from upstream.
#

SOURCE=$1
DESTINATION=$2

echo "Building git at $SOURCE to $DESTINATION"

cd $SOURCE
make clean
DESTDIR="$DESTINATION" make install prefix=/ \
    # don't bundle Perl scripts or libraries
    NO_PERL=1 \
    # don't bundle the TCL/TK GUI
    NO_TCLTK=1 \
    # don't translate Git output
    NO_GETTEXT=1 \
    # don't link to DarwinPorts if found
    NO_DARWIN_PORTS=1 \
    # use symbolic links instead of duplicating binaries
    NO_INSTALL_HARDLINKS=1 \
    # support running Git on Mavericks or later
    MACOSX_DEPLOYMENT_TARGET=10.9
cd -

# download Git LFS, verify its the right contents, and unpack it
GIT_LFS_FILE=git-lfs.tar.gz
curl -sL -o $GIT_LFS_FILE $GIT_LFS_URL
COMPUTED_SHA256=$(shasum -a 256 $GIT_LFS_FILE | awk '{print $1;}')
if [ "$COMPUTED_SHA256" = "$GIT_LFS_CHECKSUM" ]; then
  echo "Git LFS: checksums match"
  SUBFOLDER="$DESTINATION/libexec/git-core"
  # strip out any text files when extracting the Git LFS archive
  tar -xf $GIT_LFS_FILE -C $SUBFOLDER --exclude='*.sh' --exclude='*.md'  --strip-components=1
else
  echo "Git LFS: expected checksum $GIT_LFS_CHECKSUM but got $COMPUTED_SHA256"
  echo "aborting..."
  exit 1
fi
