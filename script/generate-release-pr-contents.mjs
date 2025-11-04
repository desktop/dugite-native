import { createWriteStream } from 'fs'

const git = process.env.GIT_VERSION
const g4w = process.env.G4W_VERSION
const lfs = process.env.LFS_VERSION
const gcm = process.env.GCM_VERSION

const parts = [
  ...(git ? [g4w !== git ? `Git to ${git} (G4W ${g4w})` : `Git ${git}`] : []),
  ...(lfs ? [`Git LFS to ${lfs}`] : []),
  ...(gcm ? [`GCM to ${gcm}`] : []),
]

const msg =
  parts.length > 0 ? `Update ${parts.join(', ')}` : 'Update dependencies'

console.log(`title=${msg}`)

const bodyStream = createWriteStream('pr-body.md', 'utf8')

const wl = line => bodyStream.write(line + '\n')

wl(
  `This is an automated pull request to update dependencies triggered by @${process.env.GITHUB_ACTOR} in ${process.env.GITHUB_ACTION_RUN_URL}.`
)
wl(``)

if (git) {
  if (g4w && g4w !== git) {
    wl(`- Updated Git to ${git} (G4W ${g4w})`)
  } else {
    wl(`- Updated Git to ${git}`)
  }
}

if (lfs) {
  wl(`- Updated Git LFS to ${lfs}`)
}

if (gcm) {
  wl(`- Updated GCM to ${gcm}`)
}

bodyStream.end()
