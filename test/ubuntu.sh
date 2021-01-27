#!/bin/bash

set -eu -o pipefail

export TARGET_PLATFORM=ubuntu
export TARGET_ARCH=64

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

$CURRENT_DIR/../script/build.sh
$CURRENT_DIR/../script/package.sh
