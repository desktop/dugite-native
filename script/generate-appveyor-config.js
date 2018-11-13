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
    if (platform !== 'windows') {
        throw new Error(`Unsupported platform '${platform}'`)
    }

    const git = dependencies['git']
    const gitPackage = git.packages.find(f => f.platform === platform && f.arch === arch)
    if (gitPackage == null) {
        throw new Error(`No Git package found for platform ${platform} and arch ${arch}`)
    }

    const lfs = dependencies['git-lfs']
    const lfsFile = lfs.files.find(f => f.platform === platform && f.arch === arch)
    if (lfsFile == null) {
        throw new Error(`No Git LFS file found for platform ${platform} and arch ${arch}`)
    }

    if (arch === 'amd64') {
        return {
            'TARGET_PLATFORM': 'win32',
            'WIN_ARCH': 64,
            'GIT_FOR_WINDOWS_URL': gitPackage.url,
            'GIT_FOR_WINDOWS_CHECKSUM': gitPackage.checksum,
            'GIT_LFS_CHECKSUM': lfsFile.checksum
        }
    } else if (arch === 'x86') {
        return {
            'TARGET_PLATFORM': 'win32',
            'WIN_ARCH': 32,
            'GIT_FOR_WINDOWS_URL': gitPackage.url,
            'GIT_FOR_WINDOWS_CHECKSUM': gitPackage.checksum,
            'GIT_LFS_CHECKSUM': lfsFile.checksum
        }
    } else {
        throw new Error(`Unsupported architecture '${arch}'`)
    }
}

const baseConfig = {
    'image': 'Visual Studio 2015',

    'skip_branch_with_pr': true,
    'environment': {
        'GIT_LFS_VERSION': getLFSVersion(),
        'matrix': [
            getConfig('windows', 'amd64'),
            getConfig('windows', 'x86')
        ]
    },
    'build_script': [
        'cmd: git submodule update --init --recursive',
        'bash: script\\build.sh',
        'bash: script\\package.sh',
    ],
    'test': 'off'
}

const appveyorFile = path.resolve(__dirname, '..', 'appveyor.yml')

const yaml = YAML.stringify(baseConfig)

// TODO: insert comment lines before file to indicate this is a generated
//       file and that you should update this script and then run `npm run generate-all-config`

fs.writeFileSync(appveyorFile, yaml)
