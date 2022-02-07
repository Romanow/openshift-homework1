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
  docker network create -d bridge back_net-"$STUDENT_LABEL" --label "$BASE_LABEL"-"$STUDENT_LABEL"
  docker network create -d bridge front_net-"$STUDENT_LABEL" --label "$BASE_LABEL"-"$STUDENT_LABEL"
}

createVolume() {
  docker volume create postgres_data-"$STUDENT_LABEL" --label "$BASE_LABEL"-"$STUDENT_LABEL"
}

runPostgres() {
  docker run -d \
              --name postgres \
              --network= back_net-"$STUDENT_LABEL" \
              --p 5432:5432 \
              -e POSTGRES_USER = program \
              -e POSTGRES_PASSWORD = test \
              -e POSTGRES_DB = todo_list \
              -e PGDATA = /var/lib/postgresql/data/pgdata \
              -v postgres_data-"$STUDENT_LABEL":/var/lib/postgresql/data \
              --label "$BASE_LABEL"-"$STUDENT_LABEL" \
              postgres:13-alpine
}

runBackend() {
  docker create \
          --name backend-"$STUDENT_LABEL" \
          -p 8080:8080 \
          --label "$BASE_LABEL"-"$STUDENT_LABEL" \
          backend:v1.0-"$STUDENT_LABEL"
          docker network connect back_net-"$STUDENT_LABEL" backend-"$STUDENT_LABEL"
          docker network connect front_net-"$STUDENT_LABEL" backend-"$STUDENT_LABEL"
          docker start backend-"$STUDENT_LABEL"
}

runFrontend() {
  docker run -d \
              --name frontend-"$STUDENT_LABEL" \
              --network=front_net-"$STUDENT_LABEL" \
              -p 3030:80 \
              --label "$BASE_LABEL"-"$STUDENT_LABEL"\
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
STUDENT_LABEL=KuchkarovOybek

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
