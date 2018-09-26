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

1. `git tag {version}` from the commit you wish to create a release
1. `git push origin --tags`
1. Wait a few minutes for the build to finish
1. From your machine run this command: `npm run generate-release-notes`

Pushing the tag triggers a new build for the platforms we need to support. As
each of those builds completes, the artefacts are published to a draft release
on GitHub. The `generate-release-notes` script handles generating the details
of the release, to save you manually finding the checksums.

This is the template we now use:

```
 - list of merged pull requests

## SHA-256 hashes:

{filename}
{checksum of file}

{filename}
{checksum of file}

...
```

The script requires a personal access token with `public_scope` set to the `GITHUB_ACCESS_TOKEN` environment variable, and you need to have `write` permissions to this repository for the script to succeed.

A successful run will look like this:

```
✅ Token found for shiftkey...
✅ Token has 'public_scope' scope to make changes to releases
✅ Latest release 'v2.19.0-1' is a draft
✅ Changelog has 4 entries
✅ Draft for release v2.19.0-1 updated.

🚨 Please review draft release and publish: https://github.com/desktop/dugite-native/releases/tag/untagged-3c3f4a202dd581133050
```

A problem found will stop the script with some helpful context:

```
✅ token found for shiftkey...
✅ token has 'public_scope' scope to make changes to releases...
✅ Latest release 'v2.19.0-1' is a draft...
🔴 Draft has 16 assets, expecting 20. This means the build agents are probably still going.
```

You can then look at the URL specified in the build script, verify it's good, and hit Publish to create the release.
