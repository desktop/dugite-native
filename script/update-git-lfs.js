const path = require('path')
const fs = require('fs')
const octokit = require('@octokit/rest')()
const rp = require('request-promise')

process.on('unhandledRejection', reason => {
  console.log(reason)
})

function updateDependencies(version, files) {
  const dependenciesPath = path.resolve(__dirname, '..', 'dependencies.json')
  const dependenciesText = fs.readFileSync(dependenciesPath)
  const dependencies = JSON.parse(dependenciesText)

  const gitLfs = {
    version: version,
    files: files,
  }

  const updatedDependencies = { ...dependencies, 'git-lfs': gitLfs }

  const newDepedenciesText = JSON.stringify(updatedDependencies, null, 2)

  fs.writeFileSync(dependenciesPath, newDepedenciesText, 'utf8')
}

function getPlatform(fileName) {
  if (fileName.match(/-windows-/)) {
    return 'windows'
  }
  if (fileName.match(/-darwin-/)) {
    return 'darwin'
  }
  if (fileName.match(/-linux-/)) {
    return 'linux'
  }

  throw new Error(`Unable to find platform for file: ${fileName}`)
}

function getArch(fileName) {
  if (fileName.match(/-amd64-/)) {
    return 'amd64'
  }
  if (fileName.match(/-386-/)) {
    return 'x86'
  }
  if (fileName.match(/-arm64-/)) {
    return 'arm64'
  }

  throw new Error(`Unable to find arch for file: ${fileName}`)
}

async function run() {
  const token = process.env.GITHUB_ACCESS_TOKEN
  if (token == null) {
    console.log(`🔴 No GITHUB_ACCESS_TOKEN environment variable set`)
    return
  }

  octokit.authenticate({
    type: 'token',
    token,
  })

  const user = await octokit.users.get()
  const me = user.data.login

  console.log(`✅ Token found for ${me}`)

  const owner = 'git-lfs'
  const repo = 'git-lfs'

  const release = await octokit.repos.getLatestRelease({ owner, repo })

  const { tag_name, id } = release.data
  const version = tag_name

  console.log(`✅ Newest git-lfs release '${version}'`)

  const assets = await octokit.repos.getAssets({
    owner,
    repo,
    release_id: id,
  })

  const signaturesFile = assets.data.find(a => a.name === 'sha256sums.asc')

  if (signaturesFile == null) {
    const foundFiles = assets.map(a => a.name)
    console.log(
      `🔴 Could not find signatures. Got files: ${JSON.stringify(foundFiles)}`
    )
    return
  }

  console.log(`✅ Found SHA256 signatures for release '${version}'`)

  const { url } = signaturesFile
  const options = {
    url,
    headers: {
      Accept: 'application/octet-stream',
      'User-Agent': 'dugite-native',
      Authorization: `token ${token}`,
    },
    secureProtocol: 'TLSv1_2_method',
  }

  const fileContents = await rp(options)

  const files = [
    `git-lfs-darwin-amd64-${version}.tar.gz`,
    `git-lfs-linux-amd64-${version}.tar.gz`,
    `git-lfs-linux-arm64-${version}.tar.gz`,
    `git-lfs-windows-386-${version}.zip`,
    `git-lfs-windows-amd64-${version}.zip`,
  ]

  const newFiles = []

  for (const file of files) {
    const re = new RegExp(`([0-9a-z]{64})\\s*${file}`)
    const match = re.exec(fileContents)
    if (match == null) {
      console.log(`🔴 Could not find entry for file ${platform}`)
    } else {
      newFiles.push({
        platform: getPlatform(file),
        arch: getArch(file),
        name: file,
        checksum: match[1],
      })
    }
  }

  updateDependencies(version, newFiles)

  console.log(`✅ Updated dependencies metadata to Git LFS '${version}'`)
}

run()
