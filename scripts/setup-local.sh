# local-build.sh
export CONTAINER_REGISTRY="localhost:5000"
docker compose up registry -d
./scripts/build-and-push.sh