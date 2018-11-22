# Add a new component

If you own or know of a component that you believe should be "in the box" for
`dugite-native`, please [open a new issue](https://github.com/desktop/dugite-native/issues/new)
with as much detail as possible about what the package is and why you think it
is valuable.

## Criteria

The component should satisfy as much of this criteria as possible:

 - **Git-specific** - the component extends Git via configuration, or has a
   reliable command-line interface
 - **no graphical user interface** - `dugite-native` is for use inside
   applications, and is not tailored for end-user interactions
 - **standalone** - it doesn't depend on any shared libraries or
   version-specific APIs, because this means more work for distributors
 - **cross-platform support** - a component that can be used on Windows, macOS
   and Linux is a much better candidate than a component that only runs on one
   platform, as it would be usable by a broader audience

## Build Script

For the platforms that `dugite-native` packages, there is a corresponding
`script/build-{platform}.sh` script. These will need to be updated to obtain
the sources for this component and add them to the Git distribution before
packaging.

Use environment variables to represent the contents you need from somewhere
else.

## Update Script

Aside from those features, the component should have a scriptable way to update
`dependencies.json` with the specifics it needs:

 - platform-specific resources and where to find them
 - checksums to verify the resources are correct when packaging

It will also need updates to the scripts that generate config.

A pull request to accept a new component will need this scripting support as a
pre-requisite. The maintainers are happy to work through with contributors as
part of the PR review process.

The [Updating Dependencies](https://github.com/desktop/dugite-native/blob/master/docs/updating-dependencies.md)
document has more information about this process.
