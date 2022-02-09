#!/bin/sh

set -e

buildFrontend() {
  DOCKER_BUILDKIT=1 docker build -f frontend.Dockerfile frontend/ --tag frontend:v1.0-"$STUDENT_LABEL"
}

buildBackend() {
  ./backend/gradlew clean build -p backend
  DOCKER_BUILDKIT=1 docker build -f backend.Dockerfile backend/ --tag backend:v1.0-"$STUDENT_LABEL"
}

createNetworks() {
  echo "create networks"
  docker network create -d bridge db_bridge --label $BASE_LABEL-$STUDENT_LABEL
  docker network create -d bridge app_bridge --label $BASE_LABEL-$STUDENT_LABEL
}

createVolume() {
  echo "create volume for postgres"
  docker  volume create db_data --label $BASE_LABEL-$STUDENT_LABEL
}

runPostgres() {
  echo "RUN postgres"
  docker run -d \
    --name postgres \
    --env POSTGRES_USER=postgres \
    --env POSTGRES_PASSWORD=postgres \
    --volume db_data:/var/lib/postgresql/data \
    --volume "$PWD"/backend/postgres:/docker-entrypoint-initdb.d/ \
    --network db_bridge \
    postgres:13-alpine
}

runBackend() {
  echo "RUN backend"
  docker run -d \
    --publish 8080:8080 \
    --name backend-"$STUDENT_LABEL" \
    --env "SPRING_PROFILES_ACTIVE=docker" \
    backend:v1.0-"$STUDENT_LABEL"

  docker network connect db_bridge backend-"$STUDENT_LABEL"
  docker network connect app_bridge backend-"$STUDENT_LABEL"
}

runFrontend() {
  echo "RUN frontend"
  docker run -d \
    --publish 3000:80 \
    --name frontend-"$STUDENT_LABEL" \
    frontend:v1.0-"$STUDENT_LABEL"

  docker network connect app_bridge frontend-"$STUDENT_LABEL"
}

checkResult() {
  sleep 10
  http_response=$(
    docker exec \
      frontend-"$STUDENT_LABEL" \
      curl -s -o response.txt -w "%{http_code}" http://backend-"$STUDENT_LABEL":8080/api/v1/public/items
  )

  if [ "$http_response" != "200" ]; then
    echo "Check failed"
    exit 1
  fi
}

BASE_LABEL=homework1
# TODO student surname name
STUDENT_LABEL=konyaev

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
