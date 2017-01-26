#!/bin/bash

SOURCE=$1
DESTINATION=$2

echo "Building git at $SOURCE to $DESTINATION"

cd $SOURCE
make clean
DESTDIR="$DESTINATION" make install prefix=/ \
    NO_PERL=1 \
    NO_TCLTK=1 \
    NO_GETTEXT=1 \
    NO_DARWIN_PORTS=1 \
    NO_INSTALL_HARDLINKS=1 \
    MACOSX_DEPLOYMENT_TARGET=10.9
cd -
