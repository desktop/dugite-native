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
 - some merged pull request - #ABC via @author
 - a different pull request - #XYZ via @author

## SHA-256 hashes:

{filename}
{checksum of file}

{filename}
{checksum of file}

...
```

The script requires a personal access token with `public_scope` set to the
`GITHUB_ACCESS_TOKEN` environment variable, and you need to have `write`
permissions to this repository for the script to succeed.

A successful run will look like this:

```
> dugite-native@ generate-release-notes /Users/shiftkey/src/dugite-native
> node script/generate-release-notes.js

✅ Token found for shiftkey
✅ Token has 'public_scope' scope to make changes to releases
✅ Newest release 'v2.19.0-1' is a draft
✅ All agents have finished and uploaded artefacts
✅ Draft for release v2.19.0-1 updated with changelog and artifacts

🚨 Please review draft release and publish: https://github.com/desktop/dugite-native/releases/tag/untagged-e0327b962d90374b8a57
```

You should then browse to the URL and confirm the changelog makes sense. Feel
free to remove any infrastructure changes from the changelog entries, as the
release should be focused on user-facing changes.

Once you're happy with the release, press **Publish** and you're done :tada:.

The script is very defensive and is designed to be run multiple times before you
publish. If it encounters a problem it should stop and provide some helpful
context:

```
✅ Token found for shiftkey
✅ Token has 'public_scope' scope to make changes to releases
✅ Latest release 'v2.19.0-1' is a draft
🔴 Draft has 16 assets, expecting 20. This means the build agents are probably still going...
```
