# Updating Dependencies

Dependency updates for `dugite-native` are handled via the
[Update dependencies](../.github/workflows/update-dependencies.yml) GitHub
Actions workflow. This workflow can update Git, Git for Windows, Git LFS, and
Git Credential Manager in a single run and automatically creates a pull request
with the changes.

## Running the Workflow

1. Go to the **Actions** tab in the repository
2. Select the **Update dependencies** workflow from the list
3. Click **Run workflow**
4. Configure the inputs for each dependency:
   - **Git**: `latest`, a specific version (e.g., `v2.44.0`), or `skip`
   - **Git for Windows**: `latest`, a specific version (e.g.,
     `v2.44.0.windows.1`), or `skip`
   - **Git LFS**: `latest`, a specific version (e.g., `v3.5.1`), or `skip`
   - **Git Credential Manager**: `latest`, a specific version, or `skip`
5. Click **Run workflow**

The workflow will update the selected dependencies, run prettier to format the
changes, and automatically create a pull request.

## What the Workflow Does

For each dependency that isn't skipped, the workflow:

- Fetches the latest (or specified) version from the upstream repository
- Updates the `dependencies.json` file with new URLs and checksums
- For Git: also updates the `git` submodule to the corresponding tag
- Formats all changed files with prettier
- Creates a pull request with a descriptive title and body

## Updating to Specific Versions

To update to specific versions rather than the latest:

1. Enter the exact version tag in the corresponding input field (e.g.,
   `v2.44.0` for Git, `v2.44.0.windows.1` for Git for Windows)
2. Set other dependencies to `skip` if you don't want to update them

## Self-hosted Git for Windows Binaries

In rare circumstances we may need to ship a version of dugite-native using
binaries hosted by us rather than the Git for Windows release assets. This
requires manual updates to `dependencies.json`:

1. Upload the 64-bit and 32-bit binaries to the desktop S3 bucket
2. Update the `dependencies.json` file with the new URLs (use the
   `desktop.githubusercontent.com` URL, not the direct S3 bucket URL, to benefit
   from the CDN)
3. Download both files to disk
4. Generate SHA-256 checksums for each file using `shasum -a 256 < filename`
   (macOS) and update `dependencies.json`
5. Follow the regular release process
