#!/bin/sh


set -e

buildFrontend() {
  ./backend/gradlew clean build -p backend
  DOCKER_BUILDKIT=1 docker build -f frontend.Dockerfile frontend/ --tag frontend:v1.0-"$STUDENT_LABEL"
}

buildBackend() {
  ./backend/gradlew clean build -p backend
  DOCKER_BUILDKIT=1 docker build -f backend.Dockerfile backend/ --tag backend:v1.0-"$STUDENT_LABEL"
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
  docker exec \
    frontend-romanow \
    curl -s http://backend-"$STUDENT_LABEL":8080/api/v1/public/items > /tmp/result-"$STUDENT_LABEL"

    if [ "$(cat /tmp/result-"$STUDENT_LABEL")" != "[]" ]; then
      echo "Check failed"
      exit 1
    fi
}

BASE_LABEL=homework1
STUDENT_LABEL=romanow

echo "=== Build backend backend:v1.0-$STUDENT_LABEL ==="
buildBackend

echo "=== Build frontend frontend:v1.0-$STUDENT_LABEL ==="
buildFrontend

echo "=== Create networks between backend <-> postgres and backend <-> frontend ==="
createNetworks

echo "=== Create persistence volume for postgres ==="
createVolume

echo "== Run Postgres ==="
runPostgres

echo "=== Run backend backend:v1.0-$STUDENT_LABEL ==="
runBackend

echo "=== Run frontend frontend:v1.0-$STUDENT_LABEL ==="
runFrontend

echo "=== Run check ==="
checkResult
