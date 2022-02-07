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
  docker network create -d bridge --label "$BASE_LABEL-$STUDENT_LABEL" postgres-backend-network
  docker network create -d bridge --label "$BASE_LABEL-$STUDENT_LABEL" backend-frontend-network
}

createVolume() {
  echo "TODO create volume for postgres"
  docker volume create --label "$BASE_LABEL-$STUDENT_LABEL" postgres-data
}

runPostgres() {
  echo "TODO run postgres"
  docker run -d \
    --name postgres \
    --network postgres-backend-network \
    --label "$BASE_LABEL-$STUDENT_LABEL" \
    -v postgres-data:/var/lib/postgresql/data \
    -v "$PWD"/backend/postgres:/docker-entrypoint-initdb.d \
    -e POSTGRES_USER=user \
    -e POSTGRES_PASSWORD=test \
    -p 5433:5432 \
    postgres:13

}

runBackend() {
  echo "TODO run backend"
  docker run -d \
    --name backend-"$BASE_LABEL-$STUDENT_LABEL" \
    --network postgres-backend-network \
    --label "$BASE_LABEL-$STUDENT_LABEL" \
    -e "SPRING_PROFILES_ACTIVE=docker" \
    -p 8080:8080 \
    backend:v1.0-"$STUDENT_LABEL"
  echo "Network connect front-back"
  docker network connect backend-frontend-network backend-"$BASE_LABEL-$STUDENT_LABEL"
}

runFrontend() {
  echo "RUN frontend"
  docker run -d \
    --name frontend-"$BASE_LABEL-$STUDENT_LABEL" \
    --network backend-frontend-network \
    --label "$BASE_LABEL-$STUDENT_LABEL" \
    -p 3000:80 \
    frontend:v1.0-"$STUDENT_LABEL"
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
STUDENT_LABEL=saidov

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
