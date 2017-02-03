# Contributing

This is a rather hands-off process, but here's how it all works.

## Build Matrix

This repository uses a number of Travis build agents to co-ordinate the
various builds and packages that are needed. The dependencies needed for each
agent are rather vanilla, and shouldn't need updating between releases.

## Repository Setup

### Build Step

The shell scripts to build each platform are found under the `script` folder.
Find the platform you wish to test out, update the script and submit the
change as a pull request. This will kick off and test everything as required.

Each script may expect a `source` argument, which represents where to find Git,
and each script is expected to output the files for packaging to the specified
`destination` location.

If, for whatever reason, a script needs to fail, returning a non-zero exit code
is enough to fail the build process.

### Updating Dependencies

#### Git

When building Git from source, only tagged commits are supported. Committing
the submodule change is good enough to change the built version of Git, as the
build scripts should resolve the tagged version without any other work from
the contributor.

We should build from the same source for each platform, so each platform script
should focus on the flags necessary to provide when building the app.

#### Other Dependencies

Other dependencies are documented as environment variables in the `.travis.yml`
file. As the fetching of checksums cannot easily be scripted currently, just
update the values manually from the release notes for the related project.

### Package Step

Packaging is rather consistent for each platform, and mostly focuses on
ensuring the right binaries are published and fingerprinted correctly.

#### GitHub Release

By tagging the source in this repository the build agents should then publish up
the artifacts to a draft GitHub release against the repository. All other builds
will discard their artifacts.
