# Git - The Native Bits

This repository contains the source and tooling for building Git from scratch
for the various platforms that `git-kitchen-sink` requires.

### Why?

For GitHub Desktop, rather than rely on the version of Git a user may (or may
not) have installed, we bundle an known recent version of Git which has been
optimized to remove features we don't require:

 - no linking to system libraries
 - use symlinks to reduce output size
 - no Perl runtime
 - no dependency on OpenSSL
 - no Tcl/Tk GUI
 - no translation of error messages

For other required platforms, such as Windows, we use upstream packages that
can be used in a standalone way. Git for Windows, for example, offers a
minimal environment called MinGit with each release that covers most of the
above requirements.

### Supported Platforms

 - Ubuntu Trusty
 - macOS (10.9 and up)


