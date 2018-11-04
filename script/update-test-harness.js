const fs = require('fs')
const path = require('path')
const YAML = require('node-yaml')

function writeEnvironmentToFile(os, env) {
  const environmentVariables = env.map(a => `${a} \\`).join('\n')

  const script = `build-${os}.sh`
  const fileContents = `#!/bin/bash

DIR="$( cd "$( dirname "\${BASH_SOURCE[0]}" )" && pwd )"
ROOT="$DIR/.."
SOURCE="$ROOT/git"
DESTINATION="$ROOT/build/git"

${environmentVariables}
. "$ROOT/script/${script}" $SOURCE $DESTINATION

echo "Archive contents:"
cd $DESTINATION
du -ah $DESTINATION
cd - > /dev/null

GZIP_FILE="dugite-native-$VERSION-${os}-test.tar.gz"
LZMA_FILE="dugite-native-$VERSION-${os}-test.lzma"

echo ""
echo "Creating archives..."
if [ "$(uname -s)" == "Darwin" ]; then
  tar -czf $GZIP_FILE -C $DESTINATION .
  tar --lzma -cf $LZMA_FILE -C $DESTINATION .
else
  tar -caf $GZIP_FILE -C $DESTINATION .
  tar -caf $LZMA_FILE -C $DESTINATION .
fi

if [ "$APPVEYOR" == "True" ]; then
  GZIP_CHECKSUM=$(sha256sum $GZIP_FILE | awk '{print $1;}')
  LZMA_CHECKSUM=$(sha256sum $LZMA_FILE | awk '{print $1;}')
else
  GZIP_CHECKSUM=$(shasum -a 256 $GZIP_FILE | awk '{print $1;}')
  LZMA_CHECKSUM=$(shasum -a 256 $LZMA_FILE | awk '{print $1;}')
fi

GZIP_SIZE=\$(du -h $GZIP_FILE | cut -f1)
LZMA_SIZE=\$(du -h $LZMA_FILE | cut -f1)

echo "$\{GZIP_CHECKSUM}" | tr -d '\\n' > "\${GZIP_FILE}.sha256"
echo "$\{LZMA_CHECKSUM}" | tr -d '\\n' > "\${LZMA_FILE}.sha256"

echo "Packages created:"
echo "\${GZIP_FILE} - \${GZIP_SIZE} - checksum: \${GZIP_CHECKSUM}"
echo "\${LZMA_FILE} - \${LZMA_SIZE} - checksum: \${LZMA_CHECKSUM}"`

  const destination = path.resolve(__dirname, '..', `test/${os}.sh`)
  fs.writeFileSync(destination, fileContents, { encoding: 'utf-8', mode: '777' })
}

const travisFile = path.resolve(__dirname, '..', '.travis.yml')

const yamlText = fs.readFileSync(travisFile)
const yaml = YAML.parse(yamlText)

const globalEnv = yaml['env']['global']

const platforms = yaml['matrix']['include']

for (const platform of platforms) {
  const platformEnv = platform['env']
  if (platformEnv == null) {
    continue
  }

  const env = [...globalEnv, ...platformEnv]

  const target = platformEnv[0]
  const keys = target.split('=')
  const os = keys[1].toLowerCase()

  switch (os) {
    case 'ubuntu':
    case 'macos':
    case 'win32':
      writeEnvironmentToFile(os, env)
      break
  }
}
