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

1. Use the
   [Update dependencies](https://github.com/desktop/dugite-native/actions/workflows/update-dependencies.yml)
   workflow to update the components you wish to include in the release (e.g.,
   Git, Git LFS)
1. Use the
   [Publish Release](https://github.com/desktop/dugite-native/actions/workflows/release.yml)
   workflow to create a new release
1. Wait a few minutes for the build to finish
1. Once the build is complete it will create a new draft release with all of the
   assets and suggested release notes

Confirm the changelog makes sense. Feel free to remove any infrastructure
changes from the changelog entries, as the release should be focused on
user-facing changes.

Once you're happy with the release, press **Publish** and you're done :tada:
