#!/bin/sh

set -e

buildFrontend() {
  ./backend/gradlew clean build -p backend -x test
  DOCKER_BUILDKIT=1 docker build -f frontend.Dockerfile frontend/ --tag frontend:v1.0-"$STUDENT_LABEL"
}

buildBackend() {
  ./backend/gradlew clean build -p backend -x test
  DOCKER_BUILDKIT=1 docker build -f backend.Dockerfile backend/ --tag backend:v1.0-"$STUDENT_LABEL"
}

createNetworks() {
  echo "TODO create networks"
  docker network create -d bridge --label "$BASE_LABEL-$STUDENT_LABEL" backend-network-"$STUDENT_LABEL"
  docker network create -d bridge --label "$BASE_LABEL-$STUDENT_LABEL" front-network-"$STUDENT_LABEL"
}

createVolume() {
  echo "TODO create volume for postgres"
  docker volume create postgres-data-"$STUDENT_LABEL" --label "$BASE_LABEL-$STUDENT_LABEL"
}

runPostgres() {
  echo "TODO run postgres"
  docker run --name postgres \
    --label "$BASE_LABEL-$STUDENT_LABEL" \
    -v postgres-data-"$STUDENT_LABEL":/var/lib/postgresql/data \
    -v "$PWD"/backend/postgres:/docker-entrypoint-initdb.d/ \
    --network backend-network-"$STUDENT_LABEL"  \
    -e POSTGRES_PASSWORD=postgres \
    -e POSTGRES_USER=postgres  \
    -d  postgres:13-alpine
}

runBackend() {
  echo "TODO run backend"
  docker run  \
    --name backend-"$STUDENT_LABEL" \
    --label "$BASE_LABEL-$STUDENT_LABEL" \
    --network backend-network-"$STUDENT_LABEL" \
    --env "SPRING_PROFILES_ACTIVE=docker" \
    -p 8080:8080 \
    -d backend:v1.0-"$STUDENT_LABEL"

  docker network connect front-network-"$STUDENT_LABEL" backend-"$STUDENT_LABEL"
}

runFrontend() {
  echo "RUN frontend"
  docker run -d \
    --name front-"$STUDENT_LABEL" \
    --label "$BASE_LABEL-$STUDENT_LABEL" \
    --network front-network-"$STUDENT_LABEL" \
    -p 3000:80 \
    frontend:v1.0-"$STUDENT_LABEL"
}

checkResult() {
  sleep 10
  http_response=$(
    docker exec \
      front-Axtamov-A \
      curl -s -o response.txt -w "%{http_code}" http://backend-"$STUDENT_LABEL":8080/api/v1/public/items
  )

  if [ "$http_response" != "200" ]; then
    echo "Check failed"
    exit 1
  fi
}

BASE_LABEL=homework1
# TODO student surname name
STUDENT_LABEL=Axtamov-A

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
