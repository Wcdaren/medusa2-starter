#!/bin/bash
set -e

# 加载开发环境配置
source .env.development

# 构建并推送到本地 registry
docker buildx build \
  --platform $BUILD_PLATFORM \
  -t $CONTAINER_REGISTRY/medusa-api:local \
  -f docker/api/Dockerfile \
  --push \
  .

# 测试运行
docker run -d \
  --name medusa-api-test \
  -p 9000:9000 \
  $CONTAINER_REGISTRY/medusa-api:local