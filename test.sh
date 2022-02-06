#!/bin/sh
#Test actions
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
  docker network create -d bridge backend --label "$BASE_LABEL"-"$STUDENT_LABEL"
  docker network create -d bridge frontend --label "$BASE_LABEL"-"$STUDENT_LABEL"
}

createVolume() {
  echo "create volume for postgres"
  docker volume create db-data --label "$BASE_LABEL"-"$STUDENT_LABEL"
}

runPostgres() {
  echo "run postgres"
  docker run -d \
	--name postgres \
	--network=backend \
	-p 5432:5432 \
	-e POSTGRES_USER=program \
    -e POSTGRES_PASSWORD=test \
    -e POSTGRES_DB=todo_list \
	-e PGDATA=/var/lib/postgresql/data/pgdata \
	-v db-data:/var/lib/postgresql/data \
	--label "$BASE_LABEL"-"$STUDENT_LABEL" \
	postgres:13-alpine
}

runBackend() {
  echo "run backend"
  docker create  \
    --name backend-"$STUDENT_LABEL" \
	--network=frontend \
	-p 8080:8080 \
	--label "$BASE_LABEL"-"$STUDENT_LABEL" \
	backend:v1.0-"$STUDENT_LABEL"
	docker network connect backend backend-"$STUDENT_LABEL"
	docker start backend-"$STUDENT_LABEL"
}

runFrontend() {
  echo "RUN frontend"
  docker run -d  \
	-p 3000:80 \
  	--network='frontend' \
	--label "$BASE_LABEL"-"$STUDENT_LABEL" \
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
# student surname name
STUDENT_LABEL=podolskiy

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
