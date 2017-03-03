# Dugite - The Native Bits

[![Build Status](https://api.travis-ci.com/desktop/dugite-native.svg?token=vdtkHSqgzNMgfyZkfVbP&branch=master)](https://travis-ci.com/desktop/dugite-native)

This repository contains the source and scripts for building a portable version
of Git for various platforms that [`dugite`](https://github.com/desktop/dugite)
supports.

**Note:** this is not intended to installed by end users - [go here](https://git-scm.com/)
to download Git for your operating system.

### What?

This project is designed to build a version of Git which is optimized for
scripted usage in applications, and removes many non-core features:

 - no linking to system libraries
 - use symlinks to reduce output size
 - no Perl runtime
 - no dependency on OpenSSL
 - no Tcl/Tk GUI
 - no translation of error messages
 - no 32-bit support

For some platforms, we can use upstream packages that can be consumed in a
standalone way. [Git for Windows](https://git-for-windows.github.io), for example,
offers a minimal environment called MinGit with each release that covers
most of the above requirements.

There are also additional customizations included in this toolchain:

 - Git-LFS
 - certificate bundle for Linux consumers

### Supported Platforms

 - Windows 7 and later
 - macOS 10.9 and up
 - Linux (tested on Ubuntu Precise/Trusty and Fedora 24)
