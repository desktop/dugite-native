#!/bin/bash -e
#
# General purpose functions for inspecting generated ELF binaries to understand
# static and dynamic linking details as part of the build process

check_static_linking_file() {
  if [ -z "$1" ] ; then
    # no parameter provided, fail hard
    exit 1
  fi

  # ermagherd there's two whitespace characters between 'LSB' and 'executable'
  # when running this on Travis - why is everything so terrible?
  if file "$1" | grep -q 'ELF [36][24]-bit LSB'; then
    if readelf -d "$1" | grep -q 'Shared library'; then
      echo "File: $file"
      # this is done twice rather than storing in a bash variable because
      # it's easier than trying to preserve the line endings
      echo "readelf output:"
      readelf -d "$1" | grep 'Shared library'
      # get a list of glibc versions required by the binary
      echo "objdump GLIBC output:"
      objdump -T "$1" | grep -oEi 'GLIBC_[0-9]*.[0-9]*.[0-9]*'| sort | uniq
      # confirm what version of curl is expected
      echo "objdump curl output:"
      objdump -T "$1" | grep -oEi " curl.*" | sort | uniq
      echo ""
    fi
  fi
}

check_static_linking() {
  if [ -z "$1" ] ; then
    # no parameter provided, fail hard
    exit 1
  fi

  # check all files for ELF exectuables
  find "$1" -type f -print0 | while read -r -d $'\0' file
  do
    check_static_linking_file "$file"
  done
}
