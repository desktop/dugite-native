const fs = require('fs')
const path = require('path')
const YAML = require('yaml')

const dependencies = require('../dependencies.json')

function getLFSVersion() {
  const lfs = dependencies['git-lfs']
  const fullVersion = lfs.version
  // trim the leading `v` from the version number
  return fullVersion.replace('v', '')
}

function getConfig(platform, arch) {
  const lfs = dependencies['git-lfs']
  const lfsFile = lfs.files.find(
    f => f.platform === platform && f.arch === arch
  )
  if (lfsFile == null) {
    throw new Error(
      `No Git LFS file found for platform ${platform} and arch ${arch}`
    )
  }

  if (platform === 'windows') {
    const git = dependencies['git']
    const gitPackage = git.packages.find(
      f => f.platform === platform && f.arch === arch
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
    include: [
      getConfig('linux', 'amd64'),
      getConfig('darwin', 'amd64'),
      getConfig('windows', 'amd64'),
      getConfig('windows', 'x86'),
      getConfig('linux', 'arm64'),
      // shellcheck build step
      {
        os: 'linux',
        language: 'shell',
        script: [`bash -c 'shopt -s globstar; shellcheck script/**/*.sh'`],
      },
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

// TODO: insert comment lines before file to indicate this is a generated
//       file and that you should update this script and then run `npm run generate-all-config`

fs.writeFileSync(appveyorFile, yaml)
