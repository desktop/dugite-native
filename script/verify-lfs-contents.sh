#!/bin/bash -e

verify_lfs_contents() {

  CONTENTS=""

  if [[ "$1" == *.zip ]]; then
    CONTENTS=$(unzip -qql "$1")
  elif [[ "$1" == *.tar.gz ]]; then
    CONTENTS=$(tar -tzf "$1")
  else
    echo "Unknown file type for $1"
    exit 1
  fi

  test -z "$CONTENTS" && {
    echo "Git LFS: found no contents in LFS archive, aborting..."
    exit 1
  }

  TOPLEVEL=$(echo "$CONTENTS" | cut -d/ -f2 | sort | uniq | grep .)
  
  # Sanity check to make sure we react if git-lfs starts adding more stuff to
  # their release packages. Note that this only looks that the top
  # (technically second) level folder so new stuff in the man folder won't
  # get caught here.
  # shellcheck disable=SC2015
  grep -qvE "^(CHANGELOG\.md|README\.md|git-lfs(\.exe)?|install\.sh|man)$" <<< "$TOPLEVEL" && {
    echo "Git LFS: unexpected files in the LFS archive, aborting..."
    exit 1
  } || true
}
