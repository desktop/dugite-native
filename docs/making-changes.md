# Making Changes

To improve the `dugite-native` toolchain, just find the appropriate hook.

## Update Git

If you want to incorporate a new version of Git, first ensure the submodule is
checked out to the correct tag, e.g:

```
cd git
git checkout v2.11.1
```

The package scripts will look for this tag, so non-tagged builds are not
currently supported. Commit this submodule change and publish a pull request
to test the packaging changes.

## Change how Git is built

Refer to the build scripts under the `script` folder for how we are building
Git for each platform:

 - [Windows](https://github.com/desktop/dugite-native/blob/master/script/build-win32.sh)
 - [macOS](https://github.com/desktop/dugite-native/blob/master/script/build-macos.sh)
 - [Ubuntu](https://github.com/desktop/dugite-native/blob/master/script/build-ubuntu.sh)

Ideally we should be using the same flags wherever possible, but sometimes we
need to do platform-specific things.

Windows doesn't need to be built from source, however it should be updated in
step with the other Git releases. When a new [Git for Windows](https://github.com/git-for-windows/git)
release is made available, just update the `GIT_FOR_WINDOWS_URL` and
`GIT_FOR_WINDOWS_CHECKSUM` variables in `.travis.yml` and `appveyor.yml` to use
their MinGit build.

## Update Git LFS

Packages are published for each platform from the [Git LFS](https://github.com/git-lfs/git-lfs)
repository. These are defined as environment variables in the `.travis.yml` and
`appveyor.yml` files - update the `GIT_LFS_URL` and `GIT_LFS_CHECKSUM` for all
platforms and commit the change.

## Add a new component

If there is some component you think should be incorporated into this package,
please [open a new issue](https://github.com/desktop/dugite/issues/new) with
as much detail as possible about what the package is and why you think it is
valuable.

If the maintainers agree that this is a worthy addition, you are
then welcome to contribute a pull request to incorporate this. Note that this
package is intended to be as lean as possible, so make a good case for it!
