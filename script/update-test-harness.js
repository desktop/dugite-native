const fs = require('fs')
const path = require('path')
const YAML = require('node-yaml')

function writeEnvironmentToFile(os, env) {
  const otherArgs = env.slice(1)
  const environmentVariables = otherArgs.map(a => `${a} \\`).join('\n')

  const script = `build-${os}.sh`
  const fileContents = `#!/bin/bash

DIR="$( cd "$( dirname "\${BASH_SOURCE[0]}" )" && pwd )"
ROOT="$DIR/.."
SOURCE="$ROOT/git"
DESTINATION="$ROOT/build/git"

${environmentVariables}
. "$ROOT/script/${script}" $SOURCE $DESTINATION

FILE="dugite-native-$VERSION-${os}-test.tar.gz"

tar -czf $FILE -C $DESTINATION .

echo "Archive contents:"
cd $DESTINATION
du -ah $DESTINATION
cd - > /dev/null

echo ""
SIZE=$(du -h $FILE | cut -f1)
echo "Package size: \${SIZE}"`

  const destination = path.resolve(__dirname, '..', `test/${os}.sh`)
  fs.writeFileSync(destination, fileContents, { encoding: 'utf-8', mode: '777' })
}

const travisFile = path.resolve(__dirname, '..', '.travis.yml')

const yamlText = fs.readFileSync(travisFile)
const yaml = YAML.parse(yamlText)

const platforms = yaml['matrix']['include']

for (const platform of platforms) {
  const env = platform['env']
  const target = env[0]
  const keys = target.split('=')
  const os = keys[1].toLowerCase()

  if (os === 'ubuntu') {
    writeEnvironmentToFile(os, env)
  } else if (os === 'macos') {
    writeEnvironmentToFile(os, env)
  } else if (os === 'win32') {
    writeEnvironmentToFile(os, env)
  }
}
