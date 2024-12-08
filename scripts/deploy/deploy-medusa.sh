#!/usr/bin/env bash

set -eo pipefail

# Get the directory of the script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
PROJECT_ROOT="$( cd "${SCRIPT_DIR}/../.." && pwd )"

# Default configurations
export APP_NAME="medusa"
export NAMESPACE="${NAMESPACE:-myapp}"
export ENVIRONMENT="${ENVIRONMENT:-local}"
export VERSION="${VERSION:-latest}"
export HELM_TIMEOUT="${HELM_TIMEOUT:-5m}"
export HELM_CHART_PATH="${PROJECT_ROOT}/helm-charts/${APP_NAME}"

# Logging with different levels
log() {
    local level="$1"
    shift
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${timestamp} [${level}] $*"
}

info() { log "INFO" "$@"; }
error() { log "ERROR" "$@" >&2; exit 1; }
debug() { [[ "${DEBUG:-false}" == "true" ]] && log "DEBUG" "$@" || true; }

# Debug deployment
debug_deployment() {
    info "Collecting debug information for ${APP_NAME}..."
    
    kubectl get deployment "${APP_NAME}" -n "${NAMESPACE}" -o yaml
    kubectl get pods -n "${NAMESPACE}" -l "app.kubernetes.io/name=${APP_NAME}"
    kubectl describe pod -n "${NAMESPACE}" -l "app.kubernetes.io/name=${APP_NAME}"
    docker images | grep "${APP_NAME}"
}

# Validate requirements
validate() {
    info "Validating requirements..."
    
    # Check required tools
    command -v kubectl >/dev/null 2>&1 || error "kubectl is required but not installed"
    command -v helm >/dev/null 2>&1 || error "helm is required but not installed"
    command -v docker >/dev/null 2>&1 || error "docker is required but not installed"
    
    # Check if Helm chart exists
    [ -d "${HELM_CHART_PATH}" ] || error "Helm chart not found at ${HELM_CHART_PATH}"
    
    # Check if Docker image exists
    if ! docker image inspect "${NAMESPACE}-${APP_NAME}:${VERSION}" >/dev/null 2>&1; then
        error "Docker image ${NAMESPACE}-${APP_NAME}:${VERSION} not found locally. Please build it first."
    fi
}

# Cleanup resources
cleanup() {
    info "Cleaning up resources..."
    kubectl delete pod -n "${NAMESPACE}" -l "app.kubernetes.io/name=${APP_NAME}" --force --grace-period=0 2>/dev/null || true
}

# Deploy application
deploy() {
    local repository="${NAMESPACE}-${APP_NAME}"
    local pull_policy="Never"
    local values_file="${HELM_CHART_PATH}/values.${ENVIRONMENT}.yaml"
    
    info "Starting deployment process..."
    info "Environment: ${ENVIRONMENT}"
    info "repository: ${repository}"
    info "Namespace: ${NAMESPACE}"
    info "Version: ${VERSION}"
    
    # Create namespace if it doesn't exist
    kubectl create namespace "${NAMESPACE}" --dry-run=client -o yaml | kubectl apply -f -

    # Use environment-specific values file if it exists
    local values_arg="--values ${HELM_CHART_PATH}/values.yaml"
    if [ -f "${values_file}" ]; then
        values_arg="${values_arg} --values ${values_file}"
    fi

    cleanup

    info "Deploying ${APP_NAME} with Helm..."
    if ! helm upgrade "${APP_NAME}" "${HELM_CHART_PATH}" \
        --install \
        --namespace "${NAMESPACE}" \
        --set "image.repository=${repository}" \
        --set "image.tag=${VERSION}" \
        --set "image.pullPolicy=${pull_policy}" \
        ${values_arg} \
        --timeout "${HELM_TIMEOUT}" \
        --wait \
        --debug; then
        
        info "Deployment failed. Collecting debug information..."
        debug_deployment
        error "Helm deployment failed"
    fi

    info "Waiting for pods to be ready..."
    if ! kubectl wait --for=condition=ready pod -l "app.kubernetes.io/name=${APP_NAME}" -n "${NAMESPACE}" --timeout=300s; then
        info "Pods failed to become ready. Collecting debug information..."
        debug_deployment
        error "Pods failed to become ready"
    fi

    info "Deployment completed successfully"
    kubectl get pods -n "${NAMESPACE}" -l "app.kubernetes.io/name=${APP_NAME}"
}

usage() {
    cat << EOF
Usage: $0 [options]

Options:
    -e, --environment    Set deployment environment (default: local)
    -n, --namespace      Set kubernetes namespace (default: myapp)
    -v, --version        Set application version (default: latest)
    -d, --debug         Enable debug mode
    -h, --help          Show this help message

Example:
    $0 --environment staging --namespace myapp-staging --version v1.0.0
EOF
}

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -e|--environment)
                export ENVIRONMENT="$2"
                shift 2
                ;;
            -n|--namespace)
                export NAMESPACE="$2"
                shift 2
                ;;
            -v|--version)
                export VERSION="$2"
                shift 2
                ;;
            -d|--debug)
                export DEBUG=true
                shift
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            *)
                error "Unknown option: $1"
                ;;
        esac
    done
}

main() {
    # Set error handling
    trap 'error "Script failed on line $LINENO"' ERR
    
    parse_args "$@"
    validate
    deploy
}

# Execute main function with all arguments
main "$@"