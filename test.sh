#!/bin/sh

set -e

buildFrontend() {
  DOCKER_BUILDKIT=1 docker build -f frontend.Dockerfile frontend/ --tag frontend:v1.0-"$STUDENT_LABEL"
}

buildBackend() {
  ./backend/gradlew clean build -p backend -x test
  DOCKER_BUILDKIT=1 docker build -f backend.Dockerfile backend/ --tag backend:v1.0-"$STUDENT_LABEL"
}

createNetworks() {
  echo "TODO create networks"
  docker network create --label "$BASE_LABEL"-"$STUDENT_LABEL" --driver bridge postgres-network-"$STUDENT_LABEL"
  docker network create --label "$BASE_LABEL"-"$STUDENT_LABEL" --driver bridge frontend-network-"$STUDENT_LABEL"
}

createVolume() {
  echo "Create volume for postgres"
  docker volume create --label "$BASE_LABEL"-"$STUDENT_LABEL" volume-homework1-"$STUDENT_LABEL"
}

runPostgres() {
  echo "TODO run postgres"
  docker run -dit --name postgres-"$STUDENT_LABEL" -p 5432:5432 \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=postgres \
  -e POSTGRES_DB=postgres \
  -v volume-homework1-"$STUDENT_LABEL":/var/lib/postgresql/data \
  -v "$PWD"/backend/postgres:/docker-entrypoint-initdb.d \
  --network postgres-network-"$STUDENT_LABEL" \
  postgres:13
}

runBackend() {
  sleep 10
  echo "TODO run backend"
  docker run -d --label "$BASE_LABEL"-"$STUDENT_LABEL" \
  -e "SPRING_PROFILES_ACTIVE=docker" \
  -p 8080:8080 \
  --network postgres-network-"$STUDENT_LABEL" \
  --name backend-"$STUDENT_LABEL" \
  backend:v1.0-"$STUDENT_LABEL"
  docker network connect frontend-network-"$STUDENT_LABEL" backend-"$STUDENT_LABEL"
}

runFrontend() {
  echo "RUN frontend"
  docker run -d --label "$BASE_LABEL"-"$STUDENT_LABEL" \
   -p 3000:80 --network frontend-network-"$STUDENT_LABEL" \
   --name frontend-"$STUDENT_LABEL" \
   frontend:v1.0-"$STUDENT_LABEL"
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
STUDENT_LABEL=Granovsky

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