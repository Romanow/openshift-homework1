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
  echo "TODO create networks"
  docker network create -d bridge db-backend --label $BASE_LABEL-$STUDENT_LABEL
  docker network create -d bridge frontend-backend --label $BASE_LABEL-$STUDENT_LABEL
}

createVolume() {
  echo "TODO create volume for postgres"
  docker  volume create db-volume --label $BASE_LABEL-$STUDENT_LABEL
}

runPostgres() {
  echo "TODO run postgres"
  docker run -d \
    --name postgres \
    --env POSTGRES_USER=postgres \
    --env POSTGRES_PASSWORD=postgres \
    --volume databasevolume:/var/lib/postgresql/data \
    --volume "$PWD"/backend/postgres:/docker-entrypoint-initdb.d/ \
    --network db-backend \
    postgres:13-alpine
}

runBackend() {
  echo "TODO run backend"
  docker run -d \
    --publish 8080:8080 \
    --name backend-"$STUDENT_LABEL" \
    --env "SPRING_PROFILES_ACTIVE=docker" \
    backend:v1.0-"$STUDENT_LABEL"

  docker network connect db-backend backend-"$STUDENT_LABEL"
  docker network connect frontend-backend backend-"$STUDENT_LABEL"
}

runFrontend() {
  echo "RUN frontend"
  docker run -d \
    --publish 3000:80 \
    --name frontend-"$STUDENT_LABEL" \
    frontend:v1.0-"$STUDENT_LABEL"

  docker network connect frontend-backend frontend-"$STUDENT_LABEL"
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
STUDENT_LABEL=azizbek-kobilov

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
