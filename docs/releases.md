# Releases

All releases are published using GitHub releases. Anyone with push access to the repository can create a new release.

Here's how to release:

0. `git tag {version}` from the current `master` commit
0. `git push origin --tags`
0. Wait a few minutes for the builds to start and finish
0. Edit the release notes on the tagged GitHub release 

### What Actually Happened?

Pushing the tag triggers a new build for the platforms we need to support. As each of those builds completes, the artefacts are published to a new release associated with the tag. The naming of the release is still manual, and each build agent will display the SHA-256 checksum for it's file in the build.

To speed up the manual work, here's the Markdown you should use for the release body (just replace the `{placeholder}` values):

```
{details about what's changed since the last release}

| File | SHA256 checksum |
| --- | --- |
| dugite-native-v{version}-macOS-{build}.tar.gz | `{sha1}` |
| dugite-native-v{version}-macOS-{build}.lzma | `{sha2}` |
| dugite-native-v{version}-ubuntu-{build}.tar.gz | `{sha3}` |
| dugite-native-v{version}-ubuntu-{build}.lzma | `{sha4}` |
| dugite-native-v{version}-win32-{build}.tar.gz | `{sha5}` |
| dugite-native-v{version}-win32-{build}.lzma | `{sha6}` |
```

### Versioning Scheme

Follow Git's versioning, but always have something after to indicate what our customizations look like. Use [Semver](http://semver.org/) for this.

Examples:

 - testing - `v2.12.0-rc0`
 - stable - `v2.12.0-1`
