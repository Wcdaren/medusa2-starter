#!/bin/bash
set -e

ENVIRONMENT=$1  # dev/staging/prod
VALUES_FILE="helm/values-${ENVIRONMENT}.yaml"

helm upgrade --install myapp ./helm-charts \
  -f $VALUES_FILE \
  --set storefront.image.tag=latest \
  --set medusa.image.tag=latest \
  --namespace myapp-${ENVIRONMENT} \
  --create-namespace
