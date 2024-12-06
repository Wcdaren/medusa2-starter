#!/bin/bash
set -eo pipefail

# Build medusa image
./scripts/build/build-image.sh medusa "$@"