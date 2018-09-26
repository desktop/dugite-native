# Releases

All releases are published using GitHub releases. Anyone with push access to the
repository can create a new release.

### Versioning Scheme

We should follow Git's versioning scheme, and increment the build number for other changes like incremementing Git LFS or packaging changes

Examples:

- testing - `v2.12.0-rc0`
- stable - `v2.12.0-1`

### Release Process

Here's how to release:

0. `git tag {version}` from the commit you wish to create a release
1. `git push origin --tags`
1. Wait a few minutes for the build to finish
1. From your machine run this command: `npm run generate-release-notes`

Pushing the tag triggers a new build for the platforms we need to support. As
each of those builds completes, the artefacts are published to a draft release
on GitHub. The `generate-release-notes` script handles generating the details
of the release, to save you manually finding the checksums.

This is the template that we previously used:

```
{details about what's changed since the last release}

| File | SHA256 checksum |
| --- | --- |
| dugite-native-v{version}-macOS.tar.gz | `{sha1}` |
| dugite-native-v{version}-macOS.lzma | `{sha2}` |
| dugite-native-v{version}-ubuntu.tar.gz | `{sha3}` |
| dugite-native-v{version}-ubuntu.lzma | `{sha4}` |
| dugite-native-v{version}-win32.tar.gz | `{sha5}` |
| dugite-native-v{version}-win32.lzma | `{sha6}` |
| dugite-native-v{version}-arm64.tar.gz | `{sha7}` |
| dugite-native-v{version}-arm64.lzma | `{sha8}` |
```

The script requires a personal access token with `public_scope` set to the `GITHUB_ACCESS_TOKEN` environment variable, and you need to have `write` permissions to this repository for the script to succeed.

A successful run will look like this:

```

```

A problem found will stop the script with some helpful context:

```
✅ token found for shiftkey...
✅ token has 'public_scope' scope to make changes to releases...
✅ Latest release 'v2.19.0-1' is a draft...
🔴 Draft has 16 assets, expecting 20. This means the build agents are probably still going.
```

You can then look at the URL specified in the build script, verify it's good, and hit Publish to create the release.
