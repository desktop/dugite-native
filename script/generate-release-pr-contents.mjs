import { createWriteStream } from 'fs'
import { readFile } from 'fs/promises'
import { join } from 'path'
import { execFile } from 'child_process'
import { promisify } from 'util'

const execFileAsync = promisify(execFile)

const { stdout } = await execFileAsync('git', [
  'show',
  'HEAD:dependencies.json',
])
const previousDependencies = JSON.parse(stdout)
const currentDependencies = JSON.parse(
  await readFile(join(import.meta.dirname, '..', 'dependencies.json'), 'utf8')
)

const listFormatter = new Intl.ListFormat('en')

const findG4WVersion = deps => {
  const url = deps.git.files.find(x => x.platform === 'windows')?.url

  if (url) {
    const re = /git\/releases\/download\/([^\/]+)\/.*\.zip$/
    const match = url.match(re)
    return match ? match[1] : undefined
  } else {
    return undefined
  }
}

const updates = {
  Git:
    currentDependencies.git.version !== previousDependencies.git.version
      ? {
          from: previousDependencies.git.version,
          to: currentDependencies.git.version,
        }
      : undefined,
  G4W:
    findG4WVersion(currentDependencies) !== findG4WVersion(previousDependencies)
      ? {
          from: findG4WVersion(previousDependencies),
          to: findG4WVersion(currentDependencies),
        }
      : undefined,
  LFS:
    currentDependencies['git-lfs'].version !==
    previousDependencies['git-lfs'].version
      ? {
          from: previousDependencies['git-lfs'].version,
          to: currentDependencies['git-lfs'].version,
        }
      : undefined,
  GCM:
    currentDependencies['git-credential-manager'].version !==
    previousDependencies['git-credential-manager'].version
      ? {
          from: previousDependencies['git-credential-manager'].version,
          to: currentDependencies['git-credential-manager'].version,
        }
      : undefined,
}

const updatedComponents = Array.from(
  Object.entries(updates).filter(([_, v]) => v !== undefined)
)

if (updatedComponents.length === 0) {
  console.log('title=Update dependencies')
} else {
  const parts = Object.entries(updates)
    .filter(([_, v]) => v !== undefined)
    .map(([k, v]) => `${k} to ${v.to}`)
  console.log(`title=Update ${listFormatter.format(parts)}`)
}

const bodyStream = createWriteStream('pr-body.md', 'utf8')

const wl = line => bodyStream.write(line + '\n')

wl(
  `This is an automated pull request to update dependencies triggered by @${process.env.GITHUB_ACTOR} in ${process.env.GITHUB_ACTION_RUN_URL}.`
)
wl(``)

if (updates.Git) {
  wl(`- Updated Git from ${updates.Git.from} to ${updates.Git.to}`)
}

if (updates.G4W) {
  wl(`- Updated G4W from ${updates.G4W.from} to ${updates.G4W.to}`)
}

if (updates.LFS) {
  wl(`- Updated Git LFS from ${updates.LFS.from} to ${updates.LFS.to}`)
}

if (updates.GCM) {
  wl(`- Updated GCM from ${updates.GCM.from} to ${updates.GCM.to}`)
}

bodyStream.end()
