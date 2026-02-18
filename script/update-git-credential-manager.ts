import { Octokit } from '@octokit/rest'
import { updateGitCredentialManagerDependencies } from './lib/dependencies'
import { fetchAssetChecksum } from './fetch-asset-checksum'
import yargs from 'yargs'
import { coerceVersionPrefix } from './lib/coerce-version'

process.on('unhandledRejection', reason => {
  console.error(reason)
})

async function run(): Promise<boolean> {
  const { argv } = yargs
    .usage('Usage: update-git [options]')
    .version(false)
    .option('tag', {
      default: 'latest',
      desc: 'The Git LFS tag to use',
      coerce: coerceVersionPrefix,
    })

  const token = process.env.GITHUB_ACCESS_TOKEN
  const octokit = new Octokit(token ? { auth: `token ${token}` } : {})

  if (!token) {
    console.log(
      `⚠️ No GITHUB_ACCESS_TOKEN environment variable set. Requests may be rate limited.`
    )
  }

  const owner = 'git-ecosystem'
  const repo = 'git-credential-manager'

  const release =
    argv['tag'] === 'latest'
      ? await octokit.repos.getLatestRelease({ owner, repo })
      : await octokit.repos.getReleaseByTag({ owner, repo, tag: argv['tag'] })

  const { tag_name, id } = release.data
  const clean_version = tag_name.replace(/^v/, '')

  console.log(`✅ Using git-credential-manager version '${tag_name}'`)

  const assets = await octokit.repos.listReleaseAssets({
    owner,
    repo,
    release_id: id,
  })

  const fileTemplates = [
    {
      name: `gcm-linux-x64-${clean_version}.tar.gz`,
      platform: 'linux',
      arch: 'amd64',
    },
    {
      name: `gcm-osx-arm64-${clean_version}.tar.gz`,
      platform: 'darwin',
      arch: 'arm64',
    },
    {
      name: `gcm-osx-x64-${clean_version}.tar.gz`,
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
    files.push({
      filename: ft.name,
      platform: ft.platform,
      arch: ft.arch,
      url,
      checksum,
    })
  }

  updateGitCredentialManagerDependencies(tag_name, files)

  console.log(
    `✅ Updated dependencies metadata to Git credential manager '${clean_version}'`
  )
  return true
}

run().then(success => process.exit(success ? 0 : 1))
