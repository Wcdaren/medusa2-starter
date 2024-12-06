#!/bin/bash
set -eo pipefail

# Build storefront image
./scripts/build/build-image.sh storefront "$@"