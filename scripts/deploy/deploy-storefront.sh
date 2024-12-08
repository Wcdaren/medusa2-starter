#!/usr/bin/env bash

set -eo pipefail

# Basic configuration
export APP_NAME="${APP_NAME:-storefront}"
export NAMESPACE="${NAMESPACE:-myapp}"
export ENVIRONMENT="${ENVIRONMENT:-local}"
export VERSION="${VERSION:-latest}"
export HELM_TIMEOUT="${HELM_TIMEOUT:-5m}"
export HELM_CHART_PATH="${HELM_CHART_PATH:-./helm-charts/${APP_NAME}}"

# Basic logging
log() {
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${timestamp} $*"
}

# Error handling
error() {
    log "ERROR: $*" >&2
    exit 1
}

# Debug function
debug_deployment() {
    log "Checking deployment status..."
    kubectl get deployment medusa-storefront -n "${NAMESPACE}" -o yaml
    
    log "Checking pods status..."
    kubectl get pods -n "${NAMESPACE}" -l app.kubernetes.io/name=medusa-storefront
    
    log "Checking pod details..."
    kubectl describe pod -n "${NAMESPACE}" -l app.kubernetes.io/name=medusa-storefront
    
    log "Checking docker images..."
    docker images | grep medusa-storefront
}

# Validate requirements
validate() {
    command -v kubectl >/dev/null 2>&1 || error "kubectl is required but not installed"
    command -v helm >/dev/null 2>&1 || error "helm is required but not installed"
    command -v docker >/dev/null 2>&1 || error "docker is required but not installed"
    
    [ -d "${HELM_CHART_PATH}" ] || error "Helm chart not found at ${HELM_CHART_PATH}"

    # 检查 Docker 镜像是否存在
    if ! docker image inspect "myapp-storefront:${VERSION}" >/dev/null 2>&1; then
        error "Docker image myapp-storefront:${VERSION} not found locally. Please build it first."
    fi
}

# Clean up function
cleanup() {
    log "Cleaning up resources..."
    kubectl delete pod -n "${NAMESPACE}" -l app.kubernetes.io/name=medusa-storefront --force --grace-period=0 2>/dev/null || true
    log "Cleanup completed"
}

# Core deployment function
deploy() {
    local repository="myapp-storefront"
    local pull_policy="Never"

    log "Starting deployment process..."
    log "Environment: ${ENVIRONMENT}"
    log "Namespace: ${NAMESPACE}"
    log "Application: ${APP_NAME}"
    log "Version: ${VERSION}"

    # Create namespace if it doesn't exist
    kubectl create namespace "${NAMESPACE}" --dry-run=client -o yaml | kubectl apply -f -

    # 清理旧的 pod（如果存在）
    cleanup

    log "Deploying ${APP_NAME} with Helm..."
    
    if ! helm upgrade "${APP_NAME}" "${HELM_CHART_PATH}" \
        --install \
        --namespace "${NAMESPACE}" \
        --set "image.repository=${repository}" \
        --set "image.tag=${VERSION}" \
        --set "image.pullPolicy=${pull_policy}" \
        --values "${HELM_CHART_PATH}/values.yaml" \
        --timeout "${HELM_TIMEOUT}" \
        --wait \
        --debug; then
        
        log "Deployment failed. Collecting debug information..."
        debug_deployment
        error "Helm deployment failed"
    fi

    log "Waiting for pods to be ready..."
    if ! kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=medusa-storefront -n "${NAMESPACE}" --timeout=300s; then
        log "Pods failed to become ready. Collecting debug information..."
        debug_deployment
        error "Pods failed to become ready"
    fi

    log "Deployment completed successfully"
    kubectl get pods -n "${NAMESPACE}" -l app.kubernetes.io/name=medusa-storefront
}

main() {
    # 设置错误处理
    trap 'error "Script failed on line $LINENO"' ERR
    
    validate
    deploy
}

# Execute main function
main