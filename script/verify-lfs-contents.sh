verify_lfs_contents() {
  # Sanity check to make sure we react if git-lfs starts adding more stuff to
  # their release packages. Note that this only looks that the top
  # (technically second) level folder so new stuff in the man folder won't
  # get caught here.
  test -z "`unzip -qql $1 | cut -d / -f 2 | sort | uniq | grep -vE "^(CHANGELOG\.md|README\.md|git-lfs(\.exe)?|install\.sh|man)$"`" || {
    echo "Git LFS: unexpected files in the zip, aborting..."
    exit 1
  }
}
