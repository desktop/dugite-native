# Making Changes

This document outlines how to make changes to the scripts and processes around
`dugite-native`.

## Updating Dependencies

If you need to update a dependency, refer to the [Updating Dependencies](https://github.com/desktop/dugite-native/blob/master/docs/updating-dependencies.md)
document for more information, as there should be an scripted process for each
dependency.

## Changes to build configuration

To avoid manual changes to build configurations, which can be brittle and might
introduce bugs, scripts are used to consume the `dependencies.json` file at the
root of the repository and generate the required build configuration scripts.

The base config and scripts are found in these files:

 - [Travis CI](https://github.com/desktop/dugite-native/blob/master/script/generate-travis-config.js)
 - [Appveyor](https://github.com/desktop/dugite-native/blob/master/script/generate-appveyor-config.js)

Maintainers should make a change to the relevant script and then run
`npm run generate-all-config` to regenerate all configurations, which will
combine the latest contents from `dependencies.json` with the base config
template.

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
