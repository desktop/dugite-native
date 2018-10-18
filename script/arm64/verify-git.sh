#!/bin/bash -e

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# shellcheck source=script/compute-checksum.sh
source "$CURRENT_DIR/../check-static-linking.sh"

echo "-- Static linking research"
check_static_linking "$DESTINATION"
