import * as path from 'path'
import * as fs from 'fs'

type GitHubAsset = {
  readonly platform: string
  readonly arch: string
  readonly checksum: string
  readonly name: string
}

type GitPackage = {
  readonly platform: string
  readonly arch: string
  readonly checksum: string
  readonly url: string
  readonly filename: string
}

type Dependencies = {
  'git-lfs': {
    readonly version: string
    readonly files: Array<GitHubAsset>
  }
  git: {
    readonly version: string
    readonly packages: Array<GitPackage>
  }
}

export function getDependencies(): Dependencies {
  const dependencies: Dependencies = require('../../dependencies.json')
  return dependencies
}

export function updateGitDependencies(
  version: string,
  packages: Array<GitPackage>
) {
  const dependenciesPath = path.resolve(
    __dirname,
    '..',
    '..',
    'dependencies.json'
  )
  const dependenciesText = fs.readFileSync(dependenciesPath, 'utf8')
  const dependencies = JSON.parse(dependenciesText)

  const git = {
    version: version,
    packages: packages,
  }

  const updatedDependencies: Dependencies = { ...dependencies, git }

  const newDepedenciesText = JSON.stringify(updatedDependencies, null, 2)

  fs.writeFileSync(dependenciesPath, newDepedenciesText + '\n', 'utf8')
}

export function updateGitLfsDependencies(
  version: string,
  files: Array<{
    platform: string
    arch: string
    name: string
    checksum: string
  }>
) {
  const dependenciesPath = path.resolve(
    __dirname,
    '..',
    '..',
    'dependencies.json'
  )
  const dependenciesText = fs.readFileSync(dependenciesPath, 'utf8')
  const dependencies = JSON.parse(dependenciesText)

  const gitLfs = {
    version: version,
    files: files,
  }

  const updatedDependencies = { ...dependencies, 'git-lfs': gitLfs }

  const newDepedenciesText = JSON.stringify(updatedDependencies, null, 2)

  fs.writeFileSync(dependenciesPath, newDepedenciesText, 'utf8')
}
