import { basename, join } from 'path'
import * as fs from 'fs'
import { Octokit } from '@octokit/rest'
import { readdir } from 'fs/promises'
import { execFile } from 'child_process'
import { promisify } from 'util'

const execFileAsync = promisify(execFile)

export default class GenerateReleaseNotes {
  // Nine targeted OS/arch combinations
  // two files for each targeted OS/arch
  // two checksum files for the previous
  private SUCCESSFUL_RELEASE_FILE_COUNT = 9 * 2 * 2

  /**
   * Full path to the artifacts directory
   */
  private artifactsDir: string

  /**
   * GitHub API token
   */
  private githubToken: string | undefined

  private owner = 'desktop'
  private repo = 'dugite-native'

  constructor() {
    console.log('Starting to generate release notes..')

    process.on('unhandledRejection', reason => {
      console.error(reason)
    })

    this.artifactsDir = join(__dirname, '..', 'artifacts')
    this.githubToken = process.env.GITHUB_TOKEN

    this.run()
  }

  /**
   * Do our magic to generate the release notes 🧙🏼‍♂️
   */
  async run() {
    const files = await readdir(this.artifactsDir, {
      withFileTypes: true,
      recursive: false,
    })

    let countFiles = 0
    let shaEntries: Array<{ filename: string; checksum: string }> = []

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
        shaEntries.push(this.getShaContents(join(file.parentPath, file.name)))
      }

      countFiles++
    }

    console.log(`Found ${countFiles} files in artifacts directory`)
    console.log(shaEntries)

    if (this.SUCCESSFUL_RELEASE_FILE_COUNT !== countFiles) {
      console.error(
        `🔴 Artifacts folder has ${countFiles} assets, expecting ${this.SUCCESSFUL_RELEASE_FILE_COUNT}. Please check the GH Actions artifacts to see which are missing.`
      )
      process.exit(1)
    }

    const releaseEntries = await this.generateReleaseNotesEntries()
    const draftReleaseNotes = this.generateDraftReleaseNotes(
      releaseEntries,
      shaEntries
    )
    const releaseNotesPath = __dirname + '/release_notes.txt'

    fs.writeFileSync(releaseNotesPath, draftReleaseNotes, { encoding: 'utf8' })

    console.log(
      `✅ All done! The release notes have been written to ${releaseNotesPath}`
    )
  }

  /**
   * Returns the filename (excluding .sha256) and its contents (a SHA256 checksum).
   */
  getShaContents(filePath: string): { filename: string; checksum: string } {
    const filename = basename(filePath).slice(0, -7)
    const checksum = fs.readFileSync(filePath, 'utf8')

    return { filename, checksum }
  }

  /**
   * Compares the most recent release to the one we're creating now.
   * Generates release note entries including attribution to the author.
   */
  async generateReleaseNotesEntries(): Promise<Array<string>> {
    const octokit = new Octokit({
      auth: this.githubToken ? `token ${this.githubToken}` : undefined,
    })
    const latestRelease = await octokit.repos.getLatestRelease({
      owner: this.owner,
      repo: this.repo,
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
        owner: this.owner,
        repo: this.repo,
        pull_number: pullRequestId,
      })
      const { title, number, user } = result.data
      const entry = ` - ${title} - #${number} via @${user.login}`
      releaseNotesEntries.push(entry)
    }

    return releaseNotesEntries
  }

  /**
   * Takes the release notes entries and the SHA entries, then merges them into the full draft release notes ✨
   */
  generateDraftReleaseNotes(
    releaseNotesEntries: Array<string>,
    shaEntries: Array<{ filename: string; checksum: string }>
  ): string {
    const changelogText = releaseNotesEntries.join('\n')

    const fileList = shaEntries.map(e => `**${e.filename}**\n${e.checksum}\n`)
    const fileListText = fileList.join('\n')

    const draftReleaseNotes = `${changelogText}

## SHA-256 hashes:

${fileListText}`

    return draftReleaseNotes
  }
}

new GenerateReleaseNotes()
