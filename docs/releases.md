# Releases

All releases are published using GitHub releases. Anyone with push access to the
repository can create a new release.

### Versioning

We should follow Git's versioning scheme, and only increment the build number
for other changes like incremementing Git LFS or packaging changes

Examples:

- testing - `v2.12.0-rc0`
- stable - `v2.12.0-1`

### Release Process

1. `git tag {version}` the version you wish to publish.
1. `git push --follow-tags` to ensure all new commits (and the tag) are pushed
   to the remote. Pushing the tag will start the release process.
1. Wait a few minutes for the build to finish (look for the build in
   https://github.com/desktop/dugite-native/actions)
1. Once the build is complete it will create a new draft release with all of the
   assets and suggested release notes

Confirm the changelog makes sense. Feel free to remove any infrastructure
changes from the changelog entries, as the release should be focused on
user-facing changes.

Once you're happy with the release, press **Publish** and you're done :tada:
