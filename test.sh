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
  docker network create -d bridge post-backend-network --label "$BASE_LABEL-$STUDENT_LABEL"
  docker network create -d bridge front-backend-network  --label "$BASE_LABEL-$STUDENT_LABEL"
}

createVolume() {
  docker volume create postgrvolume --label "$BASE_LABEL-$STUDENT_LABEL"
}

runPostgres() {
  docker run --name postgres -p 5432:5432 -v postgrvolume:/var/lib/postgresql/data -v "$PWD"/backend/postgres:/docker-entrypoint-initdb.d -e POSTGRES_USER=user -e POSTGRES_PASSWORD=test --network post-backend-network -d postgres:13 
}

runBackend() {
  sleep 20
  docker run --name backend-"$BASE_LABEL-$STUDENT_LABEL" --network post-backend-network -e "SPRING_PROFILES_ACTIVE=docker" -p 8080:8080 -d backend:v1.0-"$STUDENT_LABEL"
}

runFrontend() {
   docker run --name frontend-"$BASE_LABEL-$STUDENT_LABEL" --network front-backend-network -p 3000:80 -d frontend:v1.0-"$STUDENT_LABEL"
   docker network connect front-backend-network backend-"$BASE_LABEL-$STUDENT_LABEL"
}

checkResult() {
  sleep 10
  http_response=$(
    docker exec frontend-homework1-Alimov curl -v http://backend-"$STUDENT_LABEL":8080/api/v1/public/items
  )

  if [ "$http_response" != "200" ]; then
    echo "Check failed"
    exit 1
  fi
}

BASE_LABEL=homework1
# TODO student surname name
STUDENT_LABEL=Alimov

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
