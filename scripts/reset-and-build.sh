#!/usr/bin/env bash
set -euo pipefail

# Pipeline order matters:
#   1. Stop + clean volumes
#   2. Start infra only (postgres/redis/observability/minio/ollama), no app services yet
#   3. Run ALL migrations (core-platform, wabifair-commerce, rippleclio-content)
#   4. Build + start application services (tables exist now, no restart-loop)
#
# Earlier versions started app services before migrations, which crashed services
# that read DB schema at startup (e.g. recommendation-service reading
# recommendation_configs in a SELECT-before-serve pattern).

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

TOTAL_STEPS=11
step_label() {
  printf "[%s/%s]" "$1" "$TOTAL_STEPS"
}

echo "$(step_label 0) Check Docker daemon..."
if ! docker version > /dev/null 2>&1; then
  echo "Docker CLI not found. Please install Docker Desktop first."
  exit 1
fi

if ! docker info > /dev/null 2>&1; then
  echo "Docker daemon not ready. Trying to start Docker Desktop..."

  case "$(uname)" in
    Darwin)
      open -a "Docker" 2>/dev/null || true
      ;;
    Linux)
      sudo systemctl start docker 2>/dev/null || true
      ;;
  esac

  DOCKER_WAIT_RETRIES=0
  until docker info > /dev/null 2>&1; do
    DOCKER_WAIT_RETRIES=$((DOCKER_WAIT_RETRIES + 1))
    if [ "$DOCKER_WAIT_RETRIES" -ge 24 ]; then
      echo "Docker daemon is still unavailable after waiting 120 seconds."
      echo "Please open Docker Desktop and wait until engine status is Running, then rerun this script."
      exit 1
    fi
    sleep 5
  done
fi

echo "$(step_label 1) Stop and remove all containers..."
CONTAINERS=$(docker ps -aq)
if [ -n "$CONTAINERS" ]; then
  docker rm -f $CONTAINERS
fi

echo "$(step_label 2) Remove all volumes..."
VOLUMES=$(docker volume ls -q)
if [ -n "$VOLUMES" ]; then
  docker volume rm $VOLUMES
fi

echo "$(step_label 3) Start core-platform infrastructure (postgres/redis/observability)..."
(cd "$ROOT_DIR/core-platform" && INFRA_ONLY=1 bash build-services.sh) || { echo "core-platform infra failed."; exit 1; }

echo "$(step_label 4) Start rippleclio-content storage infrastructure (minio/ollama)..."
(cd "$ROOT_DIR/rippleclio-content" && INFRA_ONLY=1 bash build-services.sh) || { echo "rippleclio-content infra failed."; exit 1; }

echo "$(step_label 5) Run core-platform migrations..."
(cd "$ROOT_DIR/core-platform" && bash run-migrations.sh) || { echo "core-platform migrations failed."; exit 1; }

echo "$(step_label 6) Run wabifair-commerce migrations..."
(cd "$ROOT_DIR/wabifair-commerce" && bash run-migrations.sh) || { echo "wabifair-commerce migrations failed."; exit 1; }

echo "$(step_label 7) Run rippleclio-content migrations..."
(cd "$ROOT_DIR/rippleclio-content" && bash run-migrations.sh) || { echo "rippleclio-content migrations failed."; exit 1; }

echo "$(step_label 8) Build core-platform application services..."
(cd "$ROOT_DIR/core-platform" && SKIP_INFRA=1 bash build-services.sh) || { echo "core-platform build failed."; exit 1; }

echo "$(step_label 9) Build wabifair-commerce services..."
(cd "$ROOT_DIR/wabifair-commerce" && bash build-services.sh) || { echo "wabifair-commerce build failed."; exit 1; }

echo "$(step_label 10) Build rippleclio-content application services..."
(cd "$ROOT_DIR/rippleclio-content" && SKIP_INFRA=1 bash build-services.sh) || { echo "rippleclio-content build failed."; exit 1; }

echo "$(step_label 11) Final check: application services should already be up from step 8-10."
docker ps --filter "name=core-platform-auth" --filter "name=core-platform-revenue" --format "{{.Names}}" \
  | xargs -r -I{} docker restart {} > /dev/null 2>&1 || true
docker ps --filter "name=wabifair-commerce" --format "{{.Names}}" \
  | xargs -r -I{} docker restart {} > /dev/null 2>&1 || true
docker ps --filter "name=rippleclio" --format "{{.Names}}" \
  | xargs -r -I{} docker restart {} > /dev/null 2>&1 || true
sleep 3

echo "Done."
