# Updating Dependencies

To make it easy to manage changes in the dependencies of `dugite-native`, there
are a collection of scripts and processes that contributors can run.

These scripts require a recent version of [NodeJS](https://nodejs.org/) on their
machine. These scripts have been tested with Node 8.12, but later versions
should also be supported.

Before running any of these scripts, ensure you run `npm install` locally to get
all the dependencies requires for these scripts.

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
