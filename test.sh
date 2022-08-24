#!/bin/sh

set -e

buildFrontend() {
  DOCKER_BUILDKIT=1 docker build -f frontend.Dockerfile frontend/ --tag frontend:v1.0
}

buildBackend() {
  ./backend/gradlew clean build -p backend
  DOCKER_BUILDKIT=1 docker build -f backend.Dockerfile backend/ --tag backend:v1.0
}

createNetworks() {
  echo "TODO create networks"
}

createVolume() {
  echo "TODO create volume for postgres"
}

runPostgres() {
  echo "TODO run postgres"
}

runBackend() {
  echo "TODO run backend"
}

runFrontend() {
  echo "RUN frontend"
}

checkResult() {
  sleep 10
  http_response=$(
    docker exec \
      frontend \
      curl -s -o response.txt -w "%{http_code}" http://backend-service:8080/backend/api/v1/public/items
  )

  if [ "$http_response" != "200" ]; then
    echo "Check failed"
    exit 1
  fi
}

echo "=== Build backend backend:v1.0 ==="
buildBackend

echo "=== Build frontend frontend:v1.0 ==="
buildFrontend

echo "=== Create networks between backend <-> postgres and backend <-> frontend ==="
createNetworks

echo "=== Create persistence volume for postgres ==="
createVolume

echo "== Run Postgres ==="
runPostgres

echo "=== Run backend backend:v1.0 ==="
runBackend

echo "=== Run frontend frontend:v1.0L ==="
runFrontend

echo "=== Run check ==="
checkResult