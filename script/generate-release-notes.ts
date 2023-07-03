import * as glob from 'glob'
import { basename } from 'path'
import * as fs from 'fs'
import { Octokit } from '@octokit/rest'

export default class GenerateReleaseNotes {
  // Eight targeted OS/arch combinations
  // two files for each targeted OS/arch
  // two checksum files for the previous
  private SUCCESSFUL_RELEASE_FILE_COUNT = 8 * 2 * 2
  private args = process.argv.slice(2)
  private expectedArgs = [
    {
      key: 0,
      name: 'artifactsDir',
      description: 'full path to the artifacts directory',
    },
    {
      key: 1,
      name: 'tagName',
      description:
        'name of the GitHub tag that we use to generate the changelog',
    },
    {
      key: 2,
      name: 'githubToken',
      description: 'GitHub API token',
    },
  ]
  private expectedArgsString = this.expectedArgs
    .map(arg => `\${${arg.name}}`)
    .join(' ')

  /**
   * Full path to the artifacts directory
   */
  private artifactsDir: string

  /**
   * Name of the GitHub tag that we use to generate the changelog
   */
  private tagName: string

  /**
   * GitHub API token
   */
  private githubToken: string

  private owner = 'desktop'
  private repo = 'dugite-native'

  constructor() {
    console.log('Starting to generate release notes..')

    process.on('unhandledRejection', reason => {
      console.error(reason)
    })

    for (const arg of this.expectedArgs) {
      if (!this.args[arg.key]) {
        console.error(
          `🔴 Missing CLI argument \${${arg.name}} (${arg.description}). Please run the script as follows: node -r ts-node/register script/generate-release-notes.ts ${this.expectedArgsString}`
        )
        process.exit(1)
      }
    }

    this.artifactsDir = this.args[0]
    this.tagName = this.args[1]
    this.githubToken = this.args[2]

    this.run()
  }

  /**
   * Do our magic to generate the release notes 🧙🏼‍♂️
   */
  async run() {
    const Glob = glob.GlobSync
    const files = new Glob(this.artifactsDir + '/**/*', { nodir: true })
    let countFiles = 0
    let shaEntries: Array<{ filename: string; checksum: string }> = []

    for (const file of files.found) {
      if (file.endsWith('.sha256')) {
        shaEntries.push(this.getShaContents(file))
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
    const octokit = new Octokit({ auth: `token ${this.githubToken}` })
    const latestRelease = await octokit.repos.getLatestRelease({
      owner: this.owner,
      repo: this.repo,
    })

    const latestReleaseTag = latestRelease.data.tag_name

    console.log(
      `Comparing commits between ${latestReleaseTag} and ${this.tagName}...`
    )

    const response = await octokit.repos.compareCommits({
      owner: this.owner,
      repo: this.repo,
      base: latestReleaseTag,
      head: this.tagName,
    })

    const commits = response.data.commits

    const mergeCommitRegex = /Merge pull request #(\d{1,}) /

    const mergeCommitMessages = commits
      .filter((c: { commit: { message: string } }) =>
        c.commit.message.match(mergeCommitRegex)
      )
      .map((c: { commit: { message: string } }) => c.commit.message)

    const pullRequestIds = []

    for (const mergeCommitMessage of mergeCommitMessages) {
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
