import * as fs from 'fs'
import * as path from 'path'
import * as YAML from 'yaml'
import { getDependencies } from './lib/dependencies'

const dependencies = getDependencies()

function getLFSVersion() {
  const lfs = dependencies['git-lfs']
  const fullVersion = lfs.version
  // trim the leading `v` from the version number
  return fullVersion.replace('v', '')
}

function getConfig(platform: 'windows', arch: string) {
  const git = dependencies['git']
  const gitPackage = git.packages.find(
    f => f.platform === platform && f.arch === arch
  )
  if (gitPackage == null) {
    throw new Error(
      `No Git package found for platform ${platform} and arch ${arch}`
    )
  }

  const lfs = dependencies['git-lfs']
  const lfsFile = lfs.files.find(
    f => f.platform === platform && f.arch === arch
  )
  if (lfsFile == null) {
    throw new Error(
      `No Git LFS file found for platform ${platform} and arch ${arch}`
    )
  }

  if (arch === 'amd64') {
    return {
      TARGET_PLATFORM: 'win32',
      WIN_ARCH: 64,
      GIT_FOR_WINDOWS_URL: gitPackage.url,
      GIT_FOR_WINDOWS_CHECKSUM: gitPackage.checksum,
      GIT_LFS_CHECKSUM: lfsFile.checksum,
    }
  } else if (arch === 'x86') {
    return {
      TARGET_PLATFORM: 'win32',
      WIN_ARCH: 32,
      GIT_FOR_WINDOWS_URL: gitPackage.url,
      GIT_FOR_WINDOWS_CHECKSUM: gitPackage.checksum,
      GIT_LFS_CHECKSUM: lfsFile.checksum,
    }
  } else {
    throw new Error(`Unsupported architecture '${arch}'`)
  }
}

const baseConfig = {
  image: 'Visual Studio 2015',

  skip_branch_with_pr: false,
  environment: {
    GIT_LFS_VERSION: getLFSVersion(),
    matrix: [getConfig('windows', 'amd64'), getConfig('windows', 'x86')],
  },
  build_script: [
    'git submodule update --init --recursive',
    'bash script\\build.sh',
    'bash script\\package.sh',
  ],
  test: 'off',
}

const appveyorFile = path.resolve(__dirname, '..', 'appveyor.yml')

const yaml = YAML.stringify(baseConfig)

const commentPreamble = `# NOTE:
#
# This config file is generated from a source script and should not be modified
# manually. If you want to make changes to this config that are remembered
# between upgrades, ensure that you update \`script/generate-appveyor-config.js\`,
# run \`npm run generate-appveyor-config\` to generate a new config, and commit
# the change to the repository.
#`

const fileContents = `${commentPreamble}
${yaml}`

fs.writeFileSync(appveyorFile, fileContents)
