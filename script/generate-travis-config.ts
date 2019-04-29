import * as fs from 'fs'
import * as path from 'path'
import * as YAML from 'yaml'

/** @type {{'git-lfs': {version: string, files: Array<{platform: string, arch: string, name: string, checksum: string}>}, git: {packages: Array<{platform: string, arch: string, url: string, checksum: string}>} }} */
const dependencies = require('../dependencies.json')

function getLFSVersion() {
  const lfs = dependencies['git-lfs']
  const fullVersion = lfs.version
  // trim the leading `v` from the version number
  return fullVersion.replace('v', '')
}

function getConfig(platform: string, arch: string) {
  const lfs = dependencies['git-lfs']
  const lfsFile = lfs.files.find(
    (f: { platform: string; arch: string; url: string; checksum: string }) =>
      f.platform === platform && f.arch === arch
  )
  if (lfsFile == null) {
    throw new Error(
      `No Git LFS file found for platform ${platform} and arch ${arch}`
    )
  }

  if (platform === 'windows') {
    /** @type {{packages: Array<{platform: string, arch: string, url: string, checksum: string}>}} */
    const git = dependencies['git']
    const gitPackage = git.packages.find(
      (f: { platform: string; arch: string; url: string; checksum: string }) =>
        f.platform === platform && f.arch === arch
    )
    if (gitPackage == null) {
      throw new Error(
        `No Git package found for platform ${platform} and arch ${arch}`
      )
    }

    if (arch === 'amd64') {
      return {
        os: 'linux',
        language: 'c',
        env: [
          'TARGET_PLATFORM=win32',
          'WIN_ARCH=64',
          `GIT_FOR_WINDOWS_URL=${gitPackage.url}`,
          `GIT_FOR_WINDOWS_CHECKSUM=${gitPackage.checksum}`,
          `GIT_LFS_CHECKSUM=${lfsFile.checksum}`,
        ],
      }
    } else if (arch === 'x86') {
      return {
        os: 'linux',
        language: 'c',
        env: [
          'TARGET_PLATFORM=win32',
          'WIN_ARCH=32',
          `GIT_FOR_WINDOWS_URL=${gitPackage.url}`,
          `GIT_FOR_WINDOWS_CHECKSUM=${gitPackage.checksum}`,
          `GIT_LFS_CHECKSUM=${lfsFile.checksum}`,
        ],
      }
    } else {
      throw new Error(
        `Unsupported platform '${platform}' and architecture '${arch}'`
      )
    }
  }

  if (platform === 'darwin' && arch === 'amd64') {
    return {
      os: 'osx',
      language: 'c',
      env: ['TARGET_PLATFORM=macOS', `GIT_LFS_CHECKSUM=${lfsFile.checksum}`],
    }
  }

  if (platform === 'linux') {
    if (arch === 'amd64') {
      return {
        os: 'linux',
        language: 'c',
        env: ['TARGET_PLATFORM=ubuntu', `GIT_LFS_CHECKSUM=${lfsFile.checksum}`],
      }
    } else if (arch === 'arm64') {
      return {
        os: 'linux',
        language: 'c',
        env: ['TARGET_PLATFORM=arm64', `GIT_LFS_CHECKSUM=${lfsFile.checksum}`],
      }
    }
  }

  throw new Error(
    `Unsupported platform '${platform}' and architecture '${arch}'`
  )
}

const baseConfig = {
  sudo: 'required',
  services: ['docker'],
  env: {
    global: [`GIT_LFS_VERSION=${getLFSVersion()}`],
  },
  matrix: {
    fast_finish: true,
    include: [
      // shellcheck build step
      {
        os: 'linux',
        language: 'shell',
        script: [`bash -c 'shopt -s globstar; shellcheck script/**/*.sh'`],
      },
      // verify tooling scripts
      {
        os: 'linux',
        language: 'node_js',
        node_js: ['node'],
        script: [`npm run check && npm run prettier`],
      },
      getConfig('linux', 'amd64'),
      getConfig('darwin', 'amd64'),
      getConfig('windows', 'amd64'),
      getConfig('windows', 'x86'),
      getConfig('linux', 'arm64'),
    ],
  },

  compiler: ['gcc'],
  script: ['script/build.sh && script/package.sh'],

  branches: {
    only: ['master', '/^v[0-9]*.[0-9]*.[0.9]*.*$/'],
  },
  deploy: {
    provider: 'releases',
    api_key: '$GITHUB_TOKEN',
    file_glob: true,
    file: [
      '${TRAVIS_BUILD_DIR}/output/dugite-native-v*.tar.gz',
      '${TRAVIS_BUILD_DIR}/output/dugite-native-v*.lzma',
      '${TRAVIS_BUILD_DIR}/output/dugite-native-v*.sha256',
    ],
    skip_cleanup: true,
    draft: true,
    tag_name: '$TRAVIS_TAG',
    on: {
      tags: true,
    },
  },
}

const appveyorFile = path.resolve(__dirname, '..', '.travis.yml')

const yaml = YAML.stringify(baseConfig)

const commentPreamble = `# NOTE:
#
# This config file is generated from a source script and should not be modified
# manually. If you want to make changes to this config that are remembered
# between upgrades, ensure that you update \`script/generate-travis-config.js\`,
# run \`npm run generate-travis-config\` to generate a new config, and commit the
# change to the repository.
#`

const fileContents = `${commentPreamble}
${yaml}`

fs.writeFileSync(appveyorFile, fileContents)
