#!/bin/bash

# 设置环境变量
export DEPLOY_ENV=local
export GITHUB_SHA=latest

# 确保有 GitHub token
if [ -z "$GITHUB_TOKEN" ]; then
    echo "请设置 GITHUB_TOKEN 环境变量"
    echo "你可以从 https://github.com/settings/tokens 获取一个token"
    echo "然后运行: export GITHUB_TOKEN=your_token"
    exit 1
fi

# 启动本地 registry (如果没有运行)
if ! docker ps | grep -q "registry:2"; then
  docker run -d -p 5000:5000 --name registry registry:2
fi

# 确保本地 k8s 集群运行
if ! kubectl config get-contexts | grep -q "orbstack"; then
  echo "请确保 Kubernetes 已启用"
  exit 1
fi

# 切换到本地 k8s context
kubectl config use-context orbstack

# 创建命名空间（如果不存在）
kubectl create namespace local --dry-run=client -o yaml | kubectl apply -f -

# 拉取基础镜像（带重试机制）
pull_image() {
  local image="$1"
  local max_attempts=3
  local attempt=1
  
  while [ $attempt -le $max_attempts ]; do
    echo "尝试拉取镜像 $image (尝试 $attempt/$max_attempts)"
    if docker pull "$image"; then
      return 0
    fi
    
    echo "拉取失败，等待 5 秒后重试..."
    sleep 5
    attempt=$((attempt + 1))
  done
  
  return 1
}

# 拉取必要的镜像
if ! pull_image "node:20-slim"; then
  echo "无法拉取基础镜像，请检查网络连接"
  exit 1
fi

# 运行本地部署
act push \
  -s GITHUB_TOKEN="${GITHUB_TOKEN}" \
  --container-architecture linux/amd64 \
  --var DEPLOY_ENV=local \
  -P ubuntu-latest=node:20-slim