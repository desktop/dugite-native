# Git - The Native Bits

[![Build Status](https://travis-ci.com/desktop/git-native-bits.svg?token=vdtkHSqgzNMgfyZkfVbP&branch=master)](https://travis-ci.com/desktop/git-native-bits)

This repository contains the source and tooling for building Git from scratch
for the various platforms that [`git-kitchen-sink`](https://github.com/desktop/git-kitchen-sink)
supports.

### What?

This is a portable, optimized version of Git designed for scenarios where you are
working with Git repositories in your applications, without relying on whatever
the user may or may not have installed.

This is not intended to be an end-user tool - [go here](https://git-scm.com/) to
download Git for your operating system.

### Supported Platforms

 - Ubuntu Trusty
 - macOS (10.9 and up)
 - Windows

### Why?

This project is designed to build an up-to-date version of Git that is
optimized to remove features that aren't required for the command line Git
experience:

 - no linking to system libraries
 - use symlinks to reduce output size
 - no Perl runtime
 - no dependency on OpenSSL
 - no Tcl/Tk GUI
 - no translation of error messages

For other required platforms, we can use upstream packages that can be consumed
in a standalone way. Git for Windows, for example, offers a minimal environment
called MinGit with each release that covers most of the above requirements.

There are also some customizations included alongside the vanilla Git tooling:

 - Git-LFS
