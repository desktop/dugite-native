# Updating Dependencies

To make it easy to manage changes in the dependencies of `dugite-native`, there
are a collection of scripts and processes that contributors can run.

These scripts require a recent version of [NodeJS](https://nodejs.org/) on their
machine. These scripts have been tested with Node 8.12, but later versions
should also be supported.

Before running any of these scripts, ensure you run `npm install` locally to get
all the dependencies requires for these scripts.

## Update Git

To update to the latest stable version of Git, an automated script exists in the
repository. Assign a `GITHUB_ACCESS_TOKEN` environment variable (not strictly
necessary for testing but highly recommended when used in an automated process
such as CI) and run this command to perform this update process:

```shellsession
$ GITHUB_ACCESS_TOKEN=[token] npm run update-git

> dugite-native@ update-git /Users/shiftkey/src/dugite-native
> node script/update-git.js && npm run prettier-fix

✅ Newest git release 'v2.20.1'
✅ Token found for shiftkey
✅ Newest git-for-windows release 'v2.20.1.windows.1'
✅ Updated dependencies metadata to Git v2.20.1 (Git for Windows v2.20.1.windows.1)
```

This is the steps that this script performs:

- fetch any new tags for the `git` submodule
- find the latest (production) tag
- checkout the `git` submodule to this new tag
- find the latest Git for Windows tag that matches this pattern
- regenerate the `dependencies.json` file with the new content

You're now ready to commit these changes and create a new pull request.

### Updating Git to a specific version

From time to time it may be useful to ship a version of dugite using a version
which isn't the latest release. An example of this would be a backported
security fix. It's possible to specify the version you'd like to update to both
for the Git submodule (which covers macOS and Linux) and for Git for Windows.

```
$ npm run update-git -- --help

> dugite-native@ update-git /Users/markus/GitHub/dugite-native
> ts-node script/update-git.ts "--help"

Usage: update-git [options]

Options:
  --help                     Show help                                 [boolean]
  --tag                      The Git tag to use              [default: "latest"]
  --g4w-tag, --g4w           The Git for Windows tag to use  [default: "latest"]
  --ignore-version-mismatch  Continue update even if the Git for Windows version
                             and the Git submodule (macOS, Linux) don't match.
                             Use with caution.        [boolean] [default: false]
```

Example: Update GitHub for Windows to version `v2.19.2.windows.3` and the Git
submodule to version `v2.20.0`

```
$ npm run update-git -- --tag v2.20.0 --g4w v2.19.2.windows.3 --ignore-version-mismatch

> dugite-native@ update-git /Users/markus/GitHub/dugite-native
> ts-node script/update-git.ts "--tag" "v2.20.0" "--g4w" "v2.19.2.windows.3" "--ignore-version-mismatch"

✅ Using Git version 'v2.20.0'
🔴 No GITHUB_ACCESS_TOKEN environment variable set. Requests may be rate limited.
✅ Using Git for Windows version 'v2.19.2.windows.3'
🔴 Latest Git for Windows version is v2.19.2.windows.3 which is a different series to Git version v2.20.0
🔴 No checksum for 64-bit in release notes body
✅ Calculated checksum for 64-bit from downloaded asset
🔴 No checksum for 32-bit in release notes body
✅ Calculated checksum for 32-bit from downloaded asset
✅ Updated dependencies metadata to Git v2.20.0 (Git for Windows v2.19.2.windows.3)
```

### Update Git for Windows using self-hosted binaries

In rare circumstances we've had to ship a version of dugite-native using
binaries hosted by us rather than the Git for Windows release assets. The
process for updating just the Git for Windows binaries are pretty
straightforward.

1. Upload the 64-bit and 32-bit binaries to the desktop S3 bucket
2. Update the dependencies.json file with the new URLs (ensure that you're using
   the desktop.githubusercontent.com url and not the direct S3 bucket URL so
   that we can benefit from the CDN).
3. Download both files to disk (if you're using Safari you'll have to turn off
   the "Open safe files after downloading" option in preferences)
4. Generate SHA-256 checksums for each file using `shasum -a 256 < filename`
   (macOS) and update dependencies.json.
5. Follow the regular release process (updating the CI configs etc).

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
dependencies.json 10ms
package-lock.json 21ms
package.json 2ms
```

**You're now ready to commit these changes and create a new pull request.**
