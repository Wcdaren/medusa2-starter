#!/bin/bash
set -eo pipefail

# Configuration
APP_NAME=${1:?"App name is required"}
VERSION=${2:-"latest"}
REGISTRY=${CONTAINER_REGISTRY:-""}
REPOSITORY=${REGISTRY:+"$REGISTRY/"}myapp

# Retry configuration
MAX_RETRIES=3
RETRY_DELAY=5  # seconds

# Function to retry commands
retry_command() {
    local cmd=$1
    local n=1
    until [[ $n -gt $MAX_RETRIES ]]
    do
        echo "Attempt $n of $MAX_RETRIES"
        if eval "$cmd"; then
            return 0
        else
            if [[ $n -lt $MAX_RETRIES ]]; then
                echo "Command failed. Retrying in $RETRY_DELAY seconds..."
                sleep $RETRY_DELAY
            fi
        fi
        n=$((n + 1))
    done
    echo "Failed after $MAX_RETRIES attempts"
    return 1
}

# Validate app exists
if [[ ! -d "apps/$APP_NAME" ]]; then
    echo "Error: App '$APP_NAME' not found in apps directory"
    exit 1
fi

IMAGE_NAME="${REPOSITORY}-${APP_NAME}"
DOCKERFILE="apps/${APP_NAME}/Dockerfile"

echo "🏗️  Building ${IMAGE_NAME}:${VERSION}"

# Build image with retry
BUILD_CMD="docker build \
    --tag \"${IMAGE_NAME}:${VERSION}\" \
    --file \"${DOCKERFILE}\" \
    --build-arg APP_NAME=\"${APP_NAME}\" \
    --build-arg VERSION=\"${VERSION}\" \
    ."

retry_command "$BUILD_CMD"

# Push if registry is configured
if [[ -n "$REGISTRY" ]]; then
    echo "📦 Pushing ${IMAGE_NAME}:${VERSION}"
    PUSH_CMD="docker push \"${IMAGE_NAME}:${VERSION}\""
    retry_command "$PUSH_CMD"
fi

echo "✅ Done!"