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
  docker network create --driver bridge frontendTobackend  --label $BASE_LABEL-$STUDENT_LABEL
  docker network create --driver bridge backendTopostgres --label $BASE_LABEL-$STUDENT_LABEL
}

createVolume() {
  echo "TODO create volume for postgres"
  docker volume create databaseVolume --label $BASE_LABEL-$STUDENT_LABEL
}

runPostgres() {
  echo "TODO run postgres"
  docker run -d \
    -p 5432:5432  \
    --name postgres \
    -e POSTGRES_USER=postgres \
    -e POSTGRES_PASSWORD=postgres \
    -e POSTGRES_DB=postgres \
    --volume databaseVolume:/var/lib/postgresql/data \
    --volume $(pwd)/backend/postgres:/docker-entrypoint-initdb.d/ \
  postgres:13-alpine

  docker network connect backendTopostgres postgres
}

runBackend() {
  echo "TODO run backend"
  docker run -d -p 8080:8080 -e "SPRING_PROFILES_ACTIVE=docker"  --name backend-"$STUDENT_LABEL" backend-"$STUDENT_LABEL"

  docker network connect backendTopostgres backend-"$STUDENT_LABEL"
  docker network connect frontendTobackend backend-"$STUDENT_LABEL"
}


runFrontend() {
  echo "RUN frontend"
  docker run -d -p 3000:80 --name frontend-"$STUDENT_LABEL" frontend-"$STUDENT_LABEL"
  docker network connect frontendTobackend frontend-"$STUDENT_LABEL"
}

checkResult() {
  sleep 20
  docker exec \
    frontend-"$STUDENT_LABEL" \
    curl -s http://backend-"$STUDENT_LABEL":8080/api/v1/public/items > /tmp/result-"$STUDENT_LABEL"

    if [ "$(cat /tmp/result-"$STUDENT_LABEL")" != "[]" ]; then
      echo "Check failed"
      exit 1
    fi
}

BASE_LABEL=homework1
# TODO student surname name
STUDENT_LABEL=Nobotir

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
