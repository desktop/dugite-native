#!/bin/bash
#
# Some setup and environmental-specific functions
# to make the other scripts easier to read

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

export -f computeChecksum