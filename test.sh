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
	docker network create db-con
	docker network create api-con
}

createVolume() {
  docker volume create postgres-data
}

runPostgres() {
  docker run --name postgres --publish 5432:5432 --env POSTGRES_USER=program --env POSTGRES_PASSWORD=test --env POSTGRES_DB=todo_list --volume postgres-data:/var/lib/postgresql/data postgres:13
}

runBackend() {
  docker run -p 8080:8080 --name backend --env "SPRING_PROFILES_ACTIVE=docker" --network db-con backend:v1.0-"$STUDENT_LABEL"
  docker network connect api-con backend
}

runFrontend() {
  docker run -p 3000:80 --name frontend --network api-con frontend:v1.0-"$STUDENT_LABEL"
}

checkResult() {
  sleep 10
  http_response=$(
    docker exec \
      frontend-romanow \
      curl -s -o response.txt -w "%{http_code}" http://backend-"$STUDENT_LABEL":8080/api/v1/public/items
  )

  if [ "$http_response" != "200" ]; then
    echo "Check failed"
    exit 1
  fi
}

BASE_LABEL=homework1
# TODO student surname name
STUDENT_LABEL=alex-kim

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
