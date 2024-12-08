#!/usr/bin/env bash

# Strict mode settings (但先不设置 -u，因为我们需要先处理一些变量)
set -eo pipefail
IFS=$'\n\t'

###################
# Global Variables
###################

# Script metadata
readonly SCRIPT_NAME=$(basename "${0}")
readonly SCRIPT_DIR=$(dirname "$(readlink -f "${0}")")

# Load environment variables from .env file if it exists
if [[ -f "${SCRIPT_DIR}/.env" ]]; then
    # shellcheck disable=SC1090
    source "${SCRIPT_DIR}/.env"
fi

# Default configuration - 确保所有变量都有默认值
export APP_NAME="${APP_NAME:-medusa}"
export NAMESPACE="${NAMESPACE:-myapp}"
export ENVIRONMENT="${ENVIRONMENT:-local}"
export VERSION="${VERSION:-latest}"
export HELM_TIMEOUT="${HELM_TIMEOUT:-5m}"
export HELM_CHART_PATH="${HELM_CHART_PATH:-./helm-charts/${APP_NAME}}"
export CONFIG_PATH="${CONFIG_PATH:-${SCRIPT_DIR}/config}"
export LOG_LEVEL="${LOG_LEVEL:-info}"
export KUBE_CONTEXT="${KUBE_CONTEXT:-}"

# Docker image configuration
readonly IMAGE_NAME="myapp-${APP_NAME}"
readonly IMAGE_TAG="${VERSION}"
readonly LOCAL_REGISTRY="localhost"

###################
# Logger Module
###################

# Replace the LOG_LEVELS associative array with a function
get_log_level() {
    local level=$1
    case "$level" in
        debug) echo 0 ;;
        info)  echo 1 ;;
        warn)  echo 2 ;;
        error) echo 3 ;;
        *)     echo 3 ;;
    esac
}

# Modified log function
log() {
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # If no parameters, return
    if [ "$#" -lt 2 ]; then
        return 1
    fi

    local level=$1
    shift
    local message=$*
    
    # Get numeric values for comparison
    local current_level
    local min_level
    current_level=$(get_log_level "$level")
    min_level=$(get_log_level "$LOG_LEVEL")

    # Only log if level is sufficient
    if [ "$current_level" -ge "$min_level" ]; then
        case $level in
            debug) echo -e "\e[34m${timestamp} DEBUG: ${message}\e[0m" ;;
            info)  echo -e "\e[32m${timestamp} INFO:  ${message}\e[0m" ;;
            warn)  echo -e "\e[33m${timestamp} WARN:  ${message}\e[0m" >&2 ;;
            error) echo -e "\e[31m${timestamp} ERROR: ${message}\e[0m" >&2 ;;
        esac
    fi
}

###################
# Utility Functions
###################

cleanup() {
    local exit_code=$?
    log debug "Cleanup initiated with exit code: ${exit_code}"
    
    # Cleanup logic here if needed
    if [ $exit_code -ne 0 ]; then
        log error "Deployment failed! Check the logs for details."
    fi
    
    exit $exit_code
}

check_dependencies() {
    local missing_deps=0
    local deps=("kubectl" "helm" "docker")

    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            log error "Required dependency not found: ${dep}"
            missing_deps=1
        fi
    done

    if [ $missing_deps -eq 1 ]; then
        return 1
    fi
}

validate_environment() {
    if [ ! -d "${HELM_CHART_PATH}" ]; then
        log error "Helm chart not found at: ${HELM_CHART_PATH}"
        return 1
    fi

    # Use specific context if provided
    if [ -n "${KUBE_CONTEXT}" ]; then
        kubectl config use-context "${KUBE_CONTEXT}" || {
            log error "Failed to switch to context: ${KUBE_CONTEXT}"
            return 1
        }
    fi

    if ! kubectl cluster-info &> /dev/null; then
        log error "Unable to connect to Kubernetes cluster"
        return 1
    fi
}

###################
# Kubernetes Functions
###################

ensure_namespace() {
    log info "Ensuring namespace ${NAMESPACE} exists"
    kubectl get namespace "${NAMESPACE}" &> /dev/null || \
        kubectl create namespace "${NAMESPACE}"
}

cleanup_resources() {
    log info "Cleaning up existing resources in namespace ${NAMESPACE}"
    
    # Delete existing helm release if it exists
    if helm status "${APP_NAME}" -n "${NAMESPACE}" &> /dev/null; then
        log info "Uninstalling existing Helm release"
        helm uninstall "${APP_NAME}" -n "${NAMESPACE}" || true
    fi

    # Force delete any stuck pods
    if kubectl get pods -n "${NAMESPACE}" -l "app.kubernetes.io/name=${APP_NAME}" &> /dev/null; then
        log info "Force deleting existing pods"
        kubectl delete pods -n "${NAMESPACE}" \
            -l "app.kubernetes.io/name=${APP_NAME}" \
            --force --grace-period=0 || true
    fi

    # Wait for resources to be fully deleted
    sleep 5
}

###################
# Docker Functions
###################

prepare_image() {
    local full_image_name="${IMAGE_NAME}:${IMAGE_TAG}"
    local target_image_name

    log info "Preparing deployment image"

    # Check if image exists locally
    if ! docker image inspect "${full_image_name}" &> /dev/null; then
        log error "Image ${full_image_name} not found locally"
        return 1
    fi

    case "${ENVIRONMENT}" in
        local)
            if command -v minikube &> /dev/null && minikube status &> /dev/null; then
                log info "Loading image into Minikube"
                minikube image load "${full_image_name}"
                target_image_name="${full_image_name}"
            else
                target_image_name="${LOCAL_REGISTRY}/${full_image_name}"
                log info "Tagging image for local use: ${target_image_name}"
                docker tag "${full_image_name}" "${target_image_name}"
            fi
            ;;
        *)
            # For other environments, implement appropriate registry logic
            target_image_name="${full_image_name}"
            ;;
    esac

    echo "${target_image_name}"
}

###################
# Helm Functions
###################

deploy_with_helm() {
    local image_name=$1
    log info "Deploying ${APP_NAME} with Helm"

    # Determine pull policy based on environment
    local pull_policy="IfNotPresent"
    [ "${ENVIRONMENT}" = "local" ] && pull_policy="Never"
    # 添加更多调试信息
    log debug "Using image: ${image_name}"
    log debug "Environment: ${ENVIRONMENT}"
    log debug "Pull policy: ${pull_policy}"
    # Deploy with Helm
    helm upgrade "${APP_NAME}" "${HELM_CHART_PATH}" \
        --install \
        --namespace "${NAMESPACE}" \
        --set "image.repository=$(dirname "${image_name}")" \
        --set "image.tag=$(basename "${image_name}" | cut -d':' -f2)" \
        --set "image.pullPolicy=${pull_policy}" \
        --values "${HELM_CHART_PATH}/values.yaml" \
        --timeout "${HELM_TIMEOUT}" \
        --wait \
        --atomic \
        --debug

    log info "Helm deployment completed"
}

verify_deployment() {
    local timeout
    timeout=$((${HELM_TIMEOUT%m} * 60))
    local start_time
    start_time=$(date +%s)

    log info "Verifying deployment status"

    while true; do
        if [ $(($(date +%s) - start_time)) -gt ${timeout} ]; then
            log error "Deployment verification timed out"
            kubectl describe deployment "${APP_NAME}" -n "${NAMESPACE}"
            return 1
        fi

        local pod_status
        pod_status=$(kubectl get pods -n "${NAMESPACE}" \
            -l "app.kubernetes.io/name=${APP_NAME}" \
            -o jsonpath='{.items[0].status.phase}' 2>/dev/null || echo "NotFound")

        case "${pod_status}" in
            "Running")
                local pod_name
                pod_name=$(kubectl get pod -n "${NAMESPACE}" \
                    -l "app.kubernetes.io/name=${APP_NAME}" \
                    -o jsonpath='{.items[0].metadata.name}')
                
                if kubectl exec -n "${NAMESPACE}" "${pod_name}" \
                    -- echo "healthy" &> /dev/null; then
                    log info "Deployment verified successfully"
                    return 0
                fi
                ;;
            "NotFound")
                log warn "Waiting for pod to be created..."
                ;;
            *)
                log warn "Pod status: ${pod_status}"
                kubectl describe pod -n "${NAMESPACE}" \
                    -l "app.kubernetes.io/name=${APP_NAME}"
                ;;
        esac

        sleep 5
    done
}

###################
# Main Function
###################

main() {
    log info "Starting deployment process for ${APP_NAME} in ${ENVIRONMENT} environment"

    # Setup cleanup trap
    trap cleanup EXIT

    # Check dependencies and validate environment
    check_dependencies || exit 1
    validate_environment || exit 1

    # Prepare namespace and cleanup existing resources
    ensure_namespace
    cleanup_resources

    # Prepare and deploy
    local image_name
    image_name=$(prepare_image)
    deploy_with_helm "${image_name}"
    verify_deployment
}

# Now we can safely enable -u after all variables are defined
set -u

# Execute main function
main "$@"