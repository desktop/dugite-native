# Setup

As these scripts are dependent on the OS you have setup, I've not spent much
time testing things out about the local development experience. Please
:thumbsup: [this issue](https://github.com/desktop/dugite-native/issues/26)
if you encounter friction with running things locally and would like it to be
easier.

### Requirements

As this project depends on the toolchain you have installed, you will also need access to the same operating system you wish to compile Git for. Currently we don't need to build from source on Windows, but for macOS we do need access to the XCode toolchain. You also need a bash environment to run these scripts.

### Testing

You should be able to emulate the behaviour of Travis by setting environment variables. For example, to package for macOS you could run this:

```
GIT_LFS_URL=https://github.com/git-lfs/git-lfs/releases/download/v2.0.0/git-lfs-darwin-amd64-2.0.0.tar.gz \
GIT_LFS_CHECKSUM=fde18661baef286f0a942adf541527282cf8cd87b955690e10b60b621f9b1671 \
script/build-macos.sh ./git /tmp/build/git/
```

**NOTE:** one potential way to tidy this up could be to have helper scripts read out the details of the `.travis.yml` file so you don't have to duplicate the work.

For example, it could distill down to:

```
./test macOS /tmp/build/git
```

This would mean the contributor doesn't need to care about changes to how the pipeline works, and can focus on the behaviour of the scripts.
