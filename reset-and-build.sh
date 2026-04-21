#!/usr/bin/env bash
set -euo pipefail

echo "[0/9] Check Docker daemon..."
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

echo "[1/9] Stop and remove all containers..."
CONTAINERS=$(docker ps -aq)
if [ -n "$CONTAINERS" ]; then
  docker rm -f $CONTAINERS
fi

echo "[2/9] Remove all volumes..."
VOLUMES=$(docker volume ls -q)
if [ -n "$VOLUMES" ]; then
  docker volume rm $VOLUMES
fi

echo "[3/9] Build core-platform services..."
(cd core-platform && bash build-services.sh) || { echo "core-platform build failed."; exit 1; }

echo "[4/9] Build wabifair-commerce services..."
(cd wabifair-commerce && bash build-services.sh) || { echo "wabifair-commerce build failed."; exit 1; }

echo "[5/9] Build rippleclio-content services..."
(cd rippleclio-content && bash build-services.sh) || { echo "rippleclio-content build failed."; exit 1; }

echo "[6/9] Run core-platform migrations..."
(cd core-platform && bash run-migrations.sh) || { echo "core-platform migrations failed."; exit 1; }

echo "[7/9] Run wabifair-commerce migrations..."
(cd wabifair-commerce && bash run-migrations.sh) || { echo "wabifair-commerce migrations failed."; exit 1; }

echo "[8/9] Run rippleclio-content migrations..."
(cd rippleclio-content && bash run-migrations.sh) || { echo "rippleclio-content migrations failed."; exit 1; }

echo "[9/9] Restart application services..."
docker ps --filter "name=core-platform-auth" --filter "name=core-platform-revenue" --format "{{.Names}}" \
  | xargs -r -I{} docker restart {} > /dev/null 2>&1 || true
docker ps --filter "name=wabifair-commerce" --format "{{.Names}}" \
  | xargs -r -I{} docker restart {} > /dev/null 2>&1 || true
docker ps --filter "name=rippleclio" --format "{{.Names}}" \
  | xargs -r -I{} docker restart {} > /dev/null 2>&1 || true
sleep 3

echo "Done."
