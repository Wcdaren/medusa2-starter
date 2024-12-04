#!/bin/bash
set -e

# 启动本地 registry
docker run -d \
  -p 5000:5000 \
  --name registry \
  registry:2

# 创建开发环境配置
cp .env.template .env.development

# 设置本地环境变量
echo "Configuring local environment..."
sed -i '' 's#CONTAINER_REGISTRY=.*#CONTAINER_REGISTRY=localhost:5000#' .env.development
sed -i '' 's#REGISTRY_USERNAME=.*#REGISTRY_USERNAME=dev#' .env.development
sed -i '' 's#REGISTRY_PASSWORD=.*#REGISTRY_PASSWORD=dev123#' .env.development