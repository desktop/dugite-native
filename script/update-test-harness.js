const fs = require('fs')
const path = require('path')
const YAML = require('node-yaml')

function writeEnvironmentToFile(os, env) {
  const environmentVariables = env.map(a => `${a}`).join('\n')

  const script = `build-${os}.sh`
  const fileContents = `#!/bin/bash

${environmentVariables}

CURRENT_DIR="$( cd "$( dirname "\$\{BASH_SOURCE[0]\}" )" && pwd )"
ROOT="$CURRENT_DIR/.."
SOURCE="$ROOT/git"
DESTINATION="$ROOT/build/git"

. "$ROOT/script/${script}" $SOURCE $DESTINATION

source "$ROOT/script/compute-checksum.sh"

VERSION=$(
  cd $SOURCE || exit 1
  VERSION=$(git describe --exact-match HEAD)
  EXIT_CODE=$?

  if [ "$EXIT_CODE" == "128" ]; then
    echo "Git commit does not have tag, cannot use version to build from"
    exit 1
  fi
  echo "$VERSION"
)

(
echo "Generated bits to package at $DESTINATION:"
cd $DESTINATION
find .
)

BUILD_HASH=$(git rev-parse --short HEAD)

if ! [ -d "$DESTINATION" ]; then
  echo "No output found, exiting..."
  exit 1
fi

if [ "$TARGET_PLATFORM" == "ubuntu" ]; then
  GZIP_FILE="dugite-native-$VERSION-$BUILD_HASH-ubuntu.tar.gz"
  LZMA_FILE="dugite-native-$VERSION-$BUILD_HASH-ubuntu.lzma"
elif [ "$TARGET_PLATFORM" == "macOS" ]; then
  GZIP_FILE="dugite-native-$VERSION-$BUILD_HASH-macOS.tar.gz"
  LZMA_FILE="dugite-native-$VERSION-$BUILD_HASH-macOS.lzma"
elif [ "$TARGET_PLATFORM" == "win32" ]; then
  if [ "$WIN_ARCH" -eq "64" ]; then ARCH="x64"; else ARCH="x86"; fi
  GZIP_FILE="dugite-native-$VERSION-$BUILD_HASH-windows-$ARCH.tar.gz"
  LZMA_FILE="dugite-native-$VERSION-$BUILD_HASH-windows-$ARCH.lzma"
elif [ "$TARGET_PLATFORM" == "arm64" ]; then
  GZIP_FILE="dugite-native-$VERSION-$BUILD_HASH-arm64.tar.gz"
  LZMA_FILE="dugite-native-$VERSION-$BUILD_HASH-arm64.lzma"
else
  echo "Unable to package Git for platform $TARGET_PLATFORM"
  exit 1
fi

(
echo ""
PLATFORM=$(uname -s)
echo "Creating archives for $PLATFORM (\$\{OSTYPE\})..."
mkdir output
cd output || exit 1
if [ "$PLATFORM" == "Darwin" ]; then
  echo "Using bsdtar which has some different command flags"
  tar -czf "$GZIP_FILE" -C $DESTINATION .
  tar --lzma -cf "$LZMA_FILE" -C $DESTINATION .
elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]]; then
  echo "Using tar and 7z here because tar is unable to access lzma compression on Windows"
  tar -caf "$GZIP_FILE" -C $DESTINATION .
  # hacking around the fact that 7z refuses to write to LZMA files despite them
  # being the native format of 7z files
  NEW_LZMA_FILE="dugite-native-$VERSION-win32-test.7z"
  7z u -t7z "$NEW_LZMA_FILE" $DESTINATION/*
  mv $NEW_LZMA_FILE $LZMA_FILE
else
  echo "Using unix tar by default"
  tar -caf "$GZIP_FILE" -C $DESTINATION .
  tar -caf "$LZMA_FILE" -C $DESTINATION .
fi

GZIP_CHECKSUM=$(compute_checksum "$GZIP_FILE")
LZMA_CHECKSUM=$(compute_checksum "$LZMA_FILE")

GZIP_SIZE=$(du -h "$GZIP_FILE" | cut -f1)
LZMA_SIZE=$(du -h "$LZMA_FILE" | cut -f1)

echo "$\{GZIP_CHECKSUM}" | tr -d '\\n' > "\${GZIP_FILE}.sha256"
echo "$\{LZMA_CHECKSUM}" | tr -d '\\n' > "\${LZMA_FILE}.sha256"

echo "Packages created:"
echo "\${GZIP_FILE} - \${GZIP_SIZE} - checksum: \${GZIP_CHECKSUM}"
echo "\${LZMA_FILE} - \${LZMA_SIZE} - checksum: \${LZMA_CHECKSUM}"
)`

  const destination = path.resolve(__dirname, '..', `test/${os}.sh`)
  fs.writeFileSync(destination, fileContents, {
    encoding: 'utf-8',
    mode: '777',
  })
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
