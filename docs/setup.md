# Setup

As these scripts are dependent on the OS you have setup, I've not spent much
time testing things out about the local development experience. Please
:thumbsup: [this issue](https://github.com/desktop/dugite-native/issues/26)
if you encounter friction with running things locally and would like it to be
easier.

### Requirements

As this project depends on the toolchain you have installed, you will also need access to the same operating system you wish to compile Git for. Currently we don't need to build from source on Windows, but for macOS we do need access to the XCode toolchain. You also need a bash environment to run these scripts.

#### Fedora

These two packages are necessary to compile Git, in case you don't already have them installed:

```
sudo yum install libcurl-dev
sudo yum install expat-devel
```

### Testing

After making change to the relevant build or package scripts, you can test these out locally by running one of the test scripts:

```
$ test/macos.sh
$ test/ubuntu.sh
$ test/win32.sh
```

This script will generate the package contents under `build` at the root of the repository and dump out some diagnostics, so you can see the package contents and file sizes.

```
...
 52K	/Users/shiftkey/src/desktop/dugite-native/test/../build/git/share
 37M	/Users/shiftkey/src/desktop/dugite-native/test/../build/git

Package size:  16M
```

The two most interesting points to look at would be the uncompressed size of the folder on disk, and the package size (after compression).

These scripts will perform the same setup that is performed on Travis, and have the same constraints (macOS and Ubuntu are built from source, requiring the necessary toolchains for those platforms).

