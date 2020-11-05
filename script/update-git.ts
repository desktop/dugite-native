import path from 'path'
import crypto from 'crypto'
import ChildProcess from 'child_process'
import { Octokit, RestEndpointMethodTypes } from '@octokit/rest'
import semver from 'semver'
import { updateGitDependencies } from './lib/dependencies'
import yargs from 'yargs'
import fetch from 'node-fetch'

process.on('unhandledRejection', reason => {
  console.log(reason)
})

const root = path.dirname(__dirname)
const gitDir = path.join(root, 'git')

// OMG
type ReleaseAssets = RestEndpointMethodTypes['repos']['getLatestRelease']['response']['data']['assets']

function spawn(cmd: string, args: Array<string>, cwd: string): Promise<string> {
  return new Promise((resolve, reject) => {
    const child = ChildProcess.spawn(cmd, args, { cwd })
    let receivedData = ''

    child.on('error', reject)

    if (child.stdout === null) {
      reject(new Error('Unable to read stdout of child process'))
      return
    }

    child.stdout.on('data', (data: any) => {
      receivedData += data
    })

    child.on('close', (code: number, signal: string) => {
      if (code === 0) {
        resolve(receivedData)
      } else {
        reject(
          new Error(
            `'${cmd} ${args.join(
              ' '
            )}' exited with code ${code}, signal ${signal}`
          )
        )
      }
    })
  })
}

async function refreshGitSubmodule() {
  await spawn('git', ['submodule', 'update', '--init'], root)
  await spawn('git', ['fetch', '--tags'], gitDir)
}

async function checkout(tag: string) {
  await spawn('git', ['checkout', tag], gitDir)
}

async function getLatestStableRelease() {
  const allTags = await spawn('git', ['tag', '--sort=v:refname'], gitDir)

  const releaseTags = allTags
    .split('\n')
    .filter(tag => tag.indexOf('-rc') === -1)
    .filter(tag => semver.valid(tag) !== null)

  const sortedTags = semver.sort(releaseTags)
  const latestTag = sortedTags[sortedTags.length - 1]

  return latestTag.toString()
}

async function calculateAssetChecksum(uri: string) {
  return new Promise<string>((resolve, reject) => {
    const hs = crypto.createHash('sha256', { encoding: 'hex' })
    hs.on('finish', () => resolve(hs.read()))

    const headers: Record<string, string> = {
      'User-Agent': 'dugite-native',
      accept: 'application/octet-stream',
    }

    fetch(uri, { headers })
      .then(x =>
        x.ok
          ? Promise.resolve(x)
          : Promise.reject(new Error(`Server responded with ${x.status}`))
      )
      .then(x => x.buffer())
      .then(x => hs.end(x))
  })
}

async function getPackageDetails(
  assets: ReleaseAssets,
  body: string,
  arch: string
) {
  const archValue = arch === 'amd64' ? '64-bit' : '32-bit'

  const minGitFile = assets.find(
    a => a.name.indexOf('MinGit') !== -1 && a.name.indexOf(archValue) !== -1
  )
  if (minGitFile == null) {
    const foundFiles = assets.map(a => a.name)
    console.log(
      `🔴 Could not find ${archValue} archive. Found these files instead: ${JSON.stringify(
        foundFiles
      )}`
    )
    return null
  }

  const filename = minGitFile.name
  const checksumRe = new RegExp(`${filename}\\s*\\|\\s*([0-9a-f]{64})`)
  const match = checksumRe.exec(body)
  let checksum: string
  if (match == null || match.length !== 2) {
    console.log(`🔴 No checksum for ${archValue} in release notes body`)
    checksum = await calculateAssetChecksum(minGitFile.browser_download_url)
    console.log(`✅ Calculated checksum for ${archValue} from downloaded asset`)
  } else {
    console.log(`✅ Got checksum for ${archValue} from release notes body`)
    checksum = match[1]
  }

  return {
    platform: 'windows',
    arch,
    filename,
    url: minGitFile.browser_download_url,
    checksum,
  }
}

async function run() {
  const argv = yargs
    .usage('Usage: update-git [options]')
    .version(false)
    .option('tag', { default: 'latest', desc: 'The Git tag to use' })
    .option('g4w-tag', {
      alias: 'g4w',
      default: 'latest',
      desc: 'The Git for Windows tag to use',
    })
    .option('ignore-version-mismatch', {
      desc:
        "Continue update even if the Git for Windows version and the Git submodule (macOS, Linux) don't match. " +
        'Use with caution.',
      default: false,
      boolean: true,
    }).argv

  await refreshGitSubmodule()
  const latestGitVersion =
    argv['tag'] === 'latest' ? await getLatestStableRelease() : argv['tag']

  console.log(`✅ Using Git version '${latestGitVersion}'`)

  await checkout(latestGitVersion)

  const token = process.env.GITHUB_ACCESS_TOKEN
  const octokit = new Octokit(token ? { auth: `token ${token}` } : {})

  if (token) {
    const user = await octokit.users.getAuthenticated({})
    const me = user.data.login

    console.log(`✅ Token found for ${me}`)
  } else {
    console.log(
      `🔴 No GITHUB_ACCESS_TOKEN environment variable set. Requests may be rate limited.`
    )
  }

  const owner = 'git-for-windows'
  const repo = 'git'

  const release =
    argv['g4w-tag'] === 'latest'
      ? await octokit.repos.getLatestRelease({ owner, repo })
      : await octokit.repos.getReleaseByTag({
          owner,
          repo,
          tag: argv['g4w-tag'],
        })

  const { tag_name, body, assets } = release.data
  const version = tag_name

  console.log(`✅ Using Git for Windows version '${version}'`)

  if (!version.startsWith(latestGitVersion)) {
    console.log(
      `🔴 Latest Git for Windows version is ${version} which is a different series to Git version ${latestGitVersion}`
    )
    if (argv['ignore-version-mismatch'] !== true) {
      return
    }
  }

  const package64bit = await getPackageDetails(assets, body, 'amd64')
  const package32bit = await getPackageDetails(assets, body, 'x86')

  if (package64bit == null || package32bit == null) {
    return
  }

  updateGitDependencies(latestGitVersion, [package64bit, package32bit])

  console.log(
    `✅ Updated dependencies metadata to Git ${latestGitVersion} (Git for Windows ${version})`
  )
}

run()
