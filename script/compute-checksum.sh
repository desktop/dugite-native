#!/bin/bash
#
# General purpose function for obtaining the SHA256 checksum of a file
#
# path to the file should be the first argument

compute_checksum() {
   if [ -z "$1" ] ; then
     # no parameter provided, fail hard
     exit 1
   fi

  FILE=$1

  path_to_sha256sum=$(command -v sha256sum)
  if [ -x "$path_to_sha256sum" ] ; then
    sha256sum "$FILE" | awk '{print $1;}'
  else
    shasum -a 256 "$FILE" | awk '{print $1;}'
  fi
}