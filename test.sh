#!/bin/sh

set -e

buildFrontend() {
  #./backend/gradlew clean build -p backend
  DOCKER_BUILDKIT=1 docker build -f frontend.Dockerfile frontend/ --tag frontend:v1.0-"$STUDENT_LABEL"
}

buildBackend() {
  ./backend/gradlew clean build -p backend
  DOCKER_BUILDKIT=1 docker build -f backend.Dockerfile backend/ --tag backend:v1.0-"$STUDENT_LABEL"
}

createNetworks() {
  echo "create networks"
  docker network create --driver bridge --label "$BASE_LABEL-$STUDENT_LABEL" network-frontend-"$STUDENT_LABEL"
  docker network create --driver bridge --label "$BASE_LABEL-$STUDENT_LABEL" network-backend-"$STUDENT_LABEL"
}

createVolume() {
  echo "create volume for postgres"
  docker volume create --label "$BASE_LABEL-$STUDENT_LABEL" volume-pg-"$STUDENT_LABEL"
}

runPostgres() {
  echo "run postgres"
  docker run --name postgres --net network-backend-"$STUDENT_LABEL" -v volume-pg-"$STUDENT_LABEL":/var/lib/postgresql/data -v "$PWD"/backend/postgres:/docker-entrypoint-initdb.d -e POSTGRES_USER=postgres -e POSTGRES_PASSWORD=postgres -d library/postgres:13-alpine
}

runBackend() {
  echo "run backend"
  docker run --name backend-"$BASE_LABEL-$STUDENT_LABEL" --net network-backend-"$STUDENT_LABEL" -e "SPRING_PROFILES_ACTIVE=docker" -p 8080:8080 -d backend:v1.0-"$STUDENT_LABEL" 
}

runFrontend() {
  echo "run frontend"
  docker run --name frontend-"$BASE_LABEL-$STUDENT_LABEL" --net network-frontend-"$STUDENT_LABEL" -p 3000:80 -d frontend:v1.0-"$STUDENT_LABEL"
}

checkResult() {
  sleep 10
  http_response=$(
    docker exec \
      frontend-"$BASE_LABEL-$STUDENT_LABEL" \
      curl -s -o response.txt -w "%{http_code}" http://backend-"$BASE_LABEL-$STUDENT_LABEL":8080/api/v1/public/items
  )

  if [ "$http_response" != "200" ]; then
    echo "Check failed"
    exit 1
  fi
}

BASE_LABEL=homework1
# TODO student surname name
STUDENT_LABEL=abdunabiyev

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
