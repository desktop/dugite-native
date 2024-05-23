import { Octokit } from '@octokit/rest'
import { updateGitCredentialManagerDependencies } from './lib/dependencies'
import { fetchAssetChecksum } from './fetch-asset-checksum'

process.on('unhandledRejection', reason => {
  console.error(reason)
})

async function run(): Promise<boolean> {
  const token = process.env.GITHUB_ACCESS_TOKEN
  if (token == null) {
    console.log(`🔴 No GITHUB_ACCESS_TOKEN environment variable set`)
    return false
  }

  const octokit = new Octokit({ auth: `token ${token}` })

  const user = await octokit.users.getAuthenticated({})
  const me = user.data.login

  console.log(`✅ Token found for ${me}`)

  const owner = 'git-ecosystem'
  const repo = 'git-credential-manager'

  const release = await octokit.repos.getLatestRelease({ owner, repo })

  const { tag_name, id } = release.data
  const version = tag_name.replace(/^v/, '')

  console.log(`✅ Newest git-credential-manager release '${version}'`)

  const assets = await octokit.repos.listReleaseAssets({
    owner,
    repo,
    release_id: id,
  })

  const fileTemplates = [
    {
      name: `gcm-linux_amd64.${version}.tar.gz`,
      platform: 'linux',
      arch: 'amd64',
    },
    {
      name: `gcm-osx-arm64-${version}.tar.gz`,
      platform: 'darwin',
      arch: 'arm64',
    },
    {
      name: `gcm-osx-x64-${version}.tar.gz`,
      platform: 'darwin',
      arch: 'amd64',
    },
  ]

  const files = []

  for (const ft of fileTemplates) {
    const asset = assets.data.find(a => a.name === ft.name)

    if (!asset) {
      throw new Error(`Could not find asset for file: ${ft.name}`)
    }

    const url = asset.browser_download_url
    console.log(`⏳ Fetching checksum for ${ft.name}`)
    const checksum = await fetchAssetChecksum(url)
    console.log(`🔑 ${checksum}`)
    files.push({ ...ft, url, checksum })
  }

  updateGitCredentialManagerDependencies(version, files)

  console.log(
    `✅ Updated dependencies metadata to Git credential manager '${version}'`
  )
  return true
}

run().then(success => process.exit(success ? 0 : 1))
