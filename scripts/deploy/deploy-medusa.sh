#!/bin/bash
set -e

VERSION=${1:-"latest"}
APP="medusa"

# Build
# ./scripts/build/build-${APP}.sh ${VERSION}

# Deploy
helm upgrade --install ${APP} ./helm-charts/${APP} \
  --namespace myapp \
  --create-namespace \
  --set image.repository=myapp-${APP} \
  --set image.tag=${VERSION} \
  --values ./helm-charts/${APP}/values.yaml \
  --values ./helm-charts/${APP}/values-local.yaml