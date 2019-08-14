import Octokit from '@octokit/rest'
import rp from 'request-promise'
import { updateGitLfsDependencies } from './lib/dependencies'

process.on('unhandledRejection', reason => {
  console.log(reason)
})

function getPlatform(fileName: string) {
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

function getArch(fileName: string) {
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

  const octokit = new Octokit({ auth: `token ${token}` })

  const user = await octokit.users.getAuthenticated({})
  const me = user.data.login

  console.log(`✅ Token found for ${me}`)

  const owner = 'git-lfs'
  const repo = 'git-lfs'

  const release = await octokit.repos.getLatestRelease({ owner, repo })

  const { tag_name, id } = release.data
  const version = tag_name

  console.log(`✅ Newest git-lfs release '${version}'`)

  /** @type {{ data: Array<{name: string, url: string}>}} */
  const assets = await octokit.repos.listAssetsForRelease({
    owner,
    repo,
    release_id: id,
  })

  const signaturesFile = assets.data.find(
    (a: { name: string; url: string }) => a.name === 'sha256sums.asc'
  )

  if (signaturesFile == null) {
    const foundFiles = assets.data.map(
      (a: { name: string; url: string }) => a.name
    )
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
    const re = new RegExp(`([0-9a-z]{64})\\s\\*${file}`)
    const match = re.exec(fileContents)
    const platform = getPlatform(file)
    if (match == null) {
      console.log(`🔴 Could not find entry for file '${file}'`)
      console.log(`🔴 SHA256 checksum contents:`)
      console.log(`${fileContents}`)
      console.log()
    } else {
      newFiles.push({
        platform,
        arch: getArch(file),
        name: file,
        checksum: match[1],
      })
    }
  }

  updateGitLfsDependencies(version, newFiles)

  console.log(`✅ Updated dependencies metadata to Git LFS '${version}'`)
}

run()
