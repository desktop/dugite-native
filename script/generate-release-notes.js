const Octokit = require('@octokit/rest')
const octokit = new Octokit()
const rp = require('request-promise')

// five targeted OS/arch combinations
// two files for each targeted OS/arch
// two checksum files for the previous
const SUCCESSFUL_RELEASE_FILE_COUNT = 5 * 2 * 2

process.on('unhandledRejection', reason => {
  console.log(reason)
})

async function getBuildUrl(
  /** @type {Octokit} */ octokit,
  /** @type {string} */ owner,
  /** @type {string} */ repo,
  /** @type {string} */ ref
) {
  const response = await octokit.repos.listStatusesForRef({
    owner,
    repo,
    ref,
  })

  // Travis kicks off this build after a tag is pushed to the repository
  const statuses = response.data
  const travisStatus = statuses.find(
    s => s.context === 'continuous-integration/travis-ci/push'
  )

  if (travisStatus == null) {
    const contexts = statuses.map(s => s.context)
    console.log(
      `👀 Uh-oh, I couldn't find the right commit status. Found these contexts: ${JSON.stringify(
        contexts
      )}`
    )
    console.log(
      `Please open an issue against https://github.com/desktop/dugite-native so it can be fixed!`
    )
  } else {
    console.log(
      `👀 Follow along with the build here: ${travisStatus.target_url}`
    )
  }
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

  const user = await octokit.users.getAuthenticated({})
  const me = user.data.login

  console.log(`✅ Token found for ${me}`)
  // @ts-ignore
  const foundScopes = user.headers['x-oauth-scopes']
  if (foundScopes.indexOf('public_repo') === -1) {
    console.log(
      `🔴 Found GITHUB_ACCESS_TOKEN does not have required scope 'public_repo' which is required to read draft releases on dugite-native`
    )
    return
  }

  const owner = 'desktop'
  const repo = 'dugite-native'

  console.log(`✅ Token has 'public_scope' scope to make changes to releases`)

  const releases = await octokit.repos.listReleases({
    owner,
    repo,
    per_page: 1,
    page: 1,
  })

  const release = releases.data[0]
  const { tag_name, draft, id } = release

  if (!draft) {
    console.log(`🔴 Latest published release '${tag_name}' is not a draft`)
    return
  }

  console.log(`✅ Newest release '${tag_name}' is a draft`)

  const assets = await octokit.repos.listAssetsForRelease({
    owner,
    repo,
    release_id: id,
  })

  if (assets.data.length !== SUCCESSFUL_RELEASE_FILE_COUNT) {
    console.log(
      `🔴 Draft has ${
        assets.data.length
      } assets, expecting ${SUCCESSFUL_RELEASE_FILE_COUNT}. This means the build agents are probably still going...`
    )

    await getBuildUrl(octokit, owner, repo, tag_name)
    return
  }

  console.log(`✅ All agents have finished and uploaded artefacts`)

  const entries = []

  for (const asset of assets.data) {
    const { name, url } = asset
    if (name.endsWith('.sha256')) {
      const fileName = name.slice(0, -7)
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
      const checksum = fileContents.trim()
      entries.push({ fileName, checksum })
    }
  }

  const latestRelease = await octokit.repos.getLatestRelease({
    owner,
    repo,
  })

  const latestReleaseTag = latestRelease.data.tag_name

  /** @type {{ data: { commits: Array<{commit: { message: string }}>} }} */
  const response = await octokit.repos.compareCommits({
    owner,
    repo,
    base: latestReleaseTag,
    head: tag_name,
  })

  const commits = response.data.commits

  const mergeCommitRegex = /Merge pull request #(\d{1,}) /

  const mergeCommitMessages = commits
    .filter(c => c.commit.message.match(mergeCommitRegex))
    .map(c => c.commit.message)

  const pullRequestIds = []

  for (const mergeCommitMessage of mergeCommitMessages) {
    const match = mergeCommitRegex.exec(mergeCommitMessage)
    if (match != null && match.length === 2) {
      const num = parseInt(match[1])
      if (num != NaN) {
        pullRequestIds.push(num)
      }
    }
  }

  const releaseNotesEntries = []

  for (const pullRequestId of pullRequestIds) {
    const result = await octokit.pulls.get({
      owner,
      repo,
      number: pullRequestId,
    })
    const { title, number, user } = result.data
    const entry = ` - ${title} - #${number} via @${user.login}`
    releaseNotesEntries.push(entry)
  }
  const changelogText = releaseNotesEntries.join('\n')

  const fileList = entries.map(e => `**${e.fileName}**\n${e.checksum}\n`)
  const fileListText = fileList.join('\n')

  const draftReleaseNotes = `${changelogText}

## SHA-256 hashes:

${fileListText}`

  const numberWithoutPrefix = tag_name.substring(1)

  const result = await octokit.repos.updateRelease({
    owner: 'desktop',
    repo: 'dugite-native',
    release_id: id,
    tag_name,
    name: `Git ${numberWithoutPrefix}`,
    body: draftReleaseNotes,
  })

  const { html_url } = result.data

  console.log(
    `✅ Draft for release ${tag_name} updated with changelog and artifacts`
  )
  console.log()
  console.log(`💚 Please review draft release and publish: ${html_url}`)
}

run()
