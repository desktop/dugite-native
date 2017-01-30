# Contributing

This is a rather hands-off process, but here's how it should work.

## Requirements

 - A bash environment

## Build Matrix

This repository uses a number of Travis build agents to co-ordinate the
various builds and packages that are needed. The dependencies needed for each
agent are rather vanilla, and shouldn't need updating between releases.

## Repository Setup

### Build Scripts

The shell scripts to build each platform are found under the `script` folder.
Find the platform you wish to test out, update the script and submit the
change as a pull request. This will kick off and test everything necessary.

Each script may expect a `source` argument, which represents where to find Git,
and each script is expected to output the files for packaging to the specified
`destination` location.

If, for whatever reason, a script needs to fail, returning a non-zero exit code
is enough to fail the build process.

### Package Step

Packaging is rather consistent for each platform, and mostly focuses on
ensuring the right binaries are published and fingerprinted correctly.

## Update Dependencies

### Updating Git

When building Git from source, only tagged commits are supported. Committing
the submodule change is good enough to trigger a new build, as the build
scripts should resolve the release without any other work from the contributor.

### Updating Other Depedencies

Other dependencies are documented as environment variables in the `.travis.yml`
file. As the fetching of checksums cannot easily be scripted currently, just
update the values manually from the release notes for the related project.
