#!/bin/sh

set -e

buildFrontend() {
  ./backend/gradlew clean build -p backend
  DOCKER_BUILDKIT=1 docker build -f frontend.Dockerfile frontend/ --tag frontend-"$STUDENT_LABEL"
}

buildBackend() {
  ./backend/gradlew clean build -p backend
  DOCKER_BUILDKIT=1 docker build -f backend.Dockerfile backend/ --tag backend-"$STUDENT_LABEL"
}

createNetworks() {
  echo "TODO create networks"
docker network create --driver bridge front-backend  --label $BASE_LABEL-$STUDENT_LABEL
docker network create --driver bridge backend-postgres --label $BASE_LABEL-$STUDENT_LABEL

}

createVolume() {
  echo "TODO create volume for postgres"
docker volume create data_volume --label $BASE_LABEL-$STUDENT_LABEL
}

runPostgres() {
  echo "TODO run postgres"
docker run -d   \
    --name postgres \
    -e POSTGRES_USER=program \
    -e POSTGRES_PASSWORD=test \
    -e POSTGRES_DB=todo_list \
    --volume data_volume:/var/lib/postgresql/data \
    --volume $(pwd)/postgres:/docker-entrypoint-initdb.d/ \
postgres:13-alpine

docker network connect backend-postgres postgres

}

runBackend() {
  echo "TODO run backend"
docker run -d -p 8080:8080 -e "SPRING_PROFILES_ACTIVE=docker"  --name backend-"$STUDENT_LABEL" backend-"$STUDENT_LABEL"

docker network connect backend-postgres backend-"$STUDENT_LABEL"
docker network connect front-backend backend-"$STUDENT_LABEL"

}

runFrontend() {
  echo "RUN frontend"
docker run -d -p 3000:80 --name frontend-"$STUDENT_LABEL" frontend-"$STUDENT_LABEL"
docker network connect front-backend frontend-"$STUDENT_LABEL"

}

checkResult() {
  sleep 10
    rm -rf /tmp/result-"$STUDENT_LABEL"
    docker exec \
    frontend-"$STUDENT_LABEL" \
    curl -s http://backend-"$STUDENT_LABEL":8080/api/v1/public/items > /tmp/result-"$STUDENT_LABEL"
    chmod 777  /tmp/result-"$STUDENT_LABEL"
    if [ "$(cat /tmp/result-"$STUDENT_LABEL")" != "[]" ]; then
      echo "Check failed"
      exit 1
    fi
}

BASE_LABEL=homework1
# TODO student surname name
STUDENT_LABEL=boyarishev

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