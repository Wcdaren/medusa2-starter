#!/bin/bash
set -e

# 加载环境变量
if [ "$NODE_ENV" = "production" ]; then
  source .env.production
else
  source .env.development
fi

# 构建并推送 API 镜像
docker buildx build \
  --platform $BUILD_PLATFORM \
  -t $CONTAINER_REGISTRY/medusa-api:latest \
  -f docker/api/Dockerfile \
  --push \
  .

# 其他服务的构建命令类似...