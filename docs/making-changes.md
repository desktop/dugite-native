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

As Git LFS publishes their releases on GitHub, we have an automated script that
handles consuming these bits. Assign a `GITHUB_ACCESS_TOKEN` environment
variable and run this command to perform this update process:

```shellsession
$ GITHUB_ACCESS_TOKEN=[token] npm run update-git-lfs

> dugite-native@ update-git-lfs /Users/shiftkey/src/dugite-native
> node script/update-git-lfs.js && npm run prettier-fix

✅ Token found for shiftkey
✅ Newest git-lfs release 'v2.6.0'
✅ Found SHA256 signatures for release 'v2.6.0'
✅ Updated dependencies metadata to Git LFS 'v2.6.0'

> dugite-native@ prettier-fix /Users/shiftkey/src/dugite-native
> prettier --write **/*.y{,a}ml **/*.{js,ts,json}

.travis.yml 59ms
appveyor.yml 12ms
script/generate-appveyor-config.js 70ms
script/generate-release-notes.js 46ms
script/generate-travis-config.js 29ms
script/update-git-lfs.js 21ms
script/update-test-harness.js 13ms
dependencies.json 10ms
package-lock.json 21ms
package.json 2ms
```

Review the changes and ensure they look accurate, and then run the
`generate-all-config` script to refresh the build configs:

```shellsession
$ npm run generate-all-config

> dugite-native@ generate-all-config /Users/shiftkey/src/dugite-native
> npm run generate-appveyor-config && npm run generate-travis-config && npm run prettier-fix


> dugite-native@ generate-appveyor-config /Users/shiftkey/src/dugite-native
> node script/generate-appveyor-config.js


> dugite-native@ generate-travis-config /Users/shiftkey/src/dugite-native
> node script/generate-travis-config.js


> dugite-native@ prettier-fix /Users/shiftkey/src/dugite-native
> prettier --write **/*.y{,a}ml **/*.{js,ts,json}

.travis.yml 59ms
appveyor.yml 13ms
script/generate-appveyor-config.js 71ms
script/generate-release-notes.js 42ms
script/generate-travis-config.js 30ms
script/update-git-lfs.js 23ms
script/update-test-harness.js 10ms
dependencies.json 7ms
package-lock.json 23ms
package.json 4ms
```

You're now ready to commit these changes and create a new pull request.

## Add a new component

If there is some component you think should be incorporated into this package,
please [open a new issue](https://github.com/desktop/dugite/issues/new) with
as much detail as possible about what the package is and why you think it is
valuable.

If the maintainers agree that this is a worthy addition, you are
then welcome to contribute a pull request to incorporate this. Note that this
package is intended to be as lean as possible, so make a good case for it!
