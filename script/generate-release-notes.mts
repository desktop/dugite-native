import { join } from 'path'
import { Octokit } from '@octokit/rest'
import { readdir, readFile, writeFile } from 'fs/promises'
import { execFile } from 'child_process'
import { promisify } from 'util'
import z from 'zod'

const DependencyInfoSchema = z.record(
  z.literal(['git', 'git-lfs', 'git-credential-manager']),
  z.object({
    version: z.string(),
    files: z.array(
      z.object({
        platform: z.string(),
        arch: z.string(),
        url: z.string(),
        checksum: z.string(),
        filename: z.string(),
      })
    ),
  })
)

const findG4WVersion = (deps: z.infer<typeof DependencyInfoSchema>) => {
  const url = deps.git.files.find(x => x.platform === 'windows')?.url

  if (url) {
    const re = /git\/releases\/download\/([^\/]+)\/.*\.zip$/
    const match = url.match(re)
    return match ? match[1] : undefined
  } else {
    return undefined
  }
}

const execFileAsync = promisify(execFile)
const SUCCESSFUL_RELEASE_FILE_COUNT = 9 * 2 * 2

const owner = 'desktop'
const repo = 'dugite-native'

process.on('unhandledRejection', reason => {
  console.error(reason)
  process.exit(1)
})

/**
 * Takes the release notes entries and the SHA entries, then merges them into the full draft release notes ✨
 */
async function generateDraftReleaseNotes(
  releaseNotesEntries: Array<string>,
  shaEntries: Array<{ filename: string; checksum: string }>
) {
  const changelogText = releaseNotesEntries.join('\n')

  const fileList = shaEntries.map(e => `**${e.filename}**\n${e.checksum}\n`)
  const fileListText = fileList.join('\n')

  const dependencies = DependencyInfoSchema.parse(
    JSON.parse(
      await readFile(
        join(import.meta.dirname, '..', 'dependencies.json'),
        'utf8'
      )
    )
  )

  const g4wVersion = findG4WVersion(dependencies)

  if (!g4wVersion) {
    console.error(
      '🔴 Could not determine Git for Windows version from dependencies.json'
    )

    process.exit(1)
  }

  const draftReleaseNotes = `${changelogText}

## Versions

- Git: ${dependencies.git.version}
- Git for Windows: ${g4wVersion}
- Git LFS: ${dependencies['git-lfs'].version}
- Git Credential Manager: ${dependencies['git-credential-manager'].version}

## SHA-256 hashes:

${fileListText}`

  return draftReleaseNotes
}

/**
 * Compares the most recent release to the one we're creating now.
 * Generates release note entries including attribution to the author.
 */
async function generateReleaseNotesEntries(): Promise<Array<string>> {
  const octokit = new Octokit({
    auth: process.env.GITHUB_TOKEN
      ? `token ${process.env.GITHUB_TOKEN}`
      : undefined,
  })
  const latestRelease = await octokit.repos.getLatestRelease({
    owner: owner,
    repo: repo,
  })

  const latestReleaseTag = latestRelease.data.tag_name

  console.log(`Comparing commits between ${latestReleaseTag} and HEAD...`)

  const { stdout } = await execFileAsync('git', [
    'log',
    '-z',
    '--format=%s',
    '--merges',
    `${latestReleaseTag}..HEAD`,
  ])

  const mergeCommitRegex = /Merge pull request #(\d{1,}) /
  const pullRequestIds = []

  for (const mergeCommitMessage of stdout.split('\0')) {
    const match = mergeCommitRegex.exec(mergeCommitMessage)
    if (match != null && match.length === 2) {
      const num = parseInt(match[1])
      if (!Number.isNaN(num)) {
        pullRequestIds.push(num)
      }
    }
  }

  const releaseNotesEntries: Array<string> = []

  for (const pullRequestId of pullRequestIds) {
    const result = await octokit.pulls.get({
      owner,
      repo,
      pull_number: pullRequestId,
    })
    const { title, number, user } = result.data
    const entry = ` - ${title} - #${number} via @${user.login}`
    releaseNotesEntries.push(entry)
  }

  return releaseNotesEntries
}

console.log('Starting to generate release notes..')

const files = await readdir(join(import.meta.dirname, '..', 'artifacts'), {
  withFileTypes: true,
  recursive: false,
})

const shaEntries: Array<{ filename: string; checksum: string }> = []

for (const file of files) {
  if (!file.name.startsWith('dugite-')) {
    console.error('🔴 Unexpected file in artifacts directory:', file)
    process.exit(1)
  }
  if (!file.isFile()) {
    console.error('🔴 Unexpected entry in artifacts directory:', file)
    process.exit(1)
  }
  if (file.name.endsWith('.sha256')) {
    shaEntries.push({
      filename: file.name.slice(0, -'.sha256'.length),
      checksum: (
        await readFile(
          join(import.meta.dirname, '..', 'artifacts', file.name),
          'utf8'
        )
      ).trim(),
    })
  }
}

console.log(`Found ${files.length} files in artifacts directory`)
console.log(shaEntries)

if (SUCCESSFUL_RELEASE_FILE_COUNT !== files.length) {
  console.error(
    `🔴 Artifacts folder has ${files.length} assets, expecting ${SUCCESSFUL_RELEASE_FILE_COUNT}. Please check the GH Actions artifacts to see which are missing.`
  )
  process.exit(1)
}

const releaseEntries = await generateReleaseNotesEntries()
const draftReleaseNotes = await generateDraftReleaseNotes(
  releaseEntries,
  shaEntries
)
const releaseNotesPath = join(import.meta.dirname, 'release_notes.txt')

await writeFile(releaseNotesPath, draftReleaseNotes, { encoding: 'utf8' })

console.log(
  `✅ All done! The release notes have been written to ${releaseNotesPath}`
)
