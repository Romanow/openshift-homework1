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
  echo "TODO create networks"
  docker network create --driver bridge frontendTobackend  --label $BASE_LABEL-$STUDENT_LABEL
  docker network create --driver bridge backendTopostgres --label $BASE_LABEL-$STUDENT_LABEL
}

createVolume() {
  echo "TODO create volume for postgres"
  docker volume create databaseVolume --label $BASE_LABEL-$STUDENT_LABEL
}

#runPostgres() {
 # echo "TODO run postgres"
  #docker run  -p 5432:5432 --name postgres -e POSTGRES_USER=postgres -e POSTGRES_PASSWORD=postgres -e POSTGRES_DB=postgres --volume databaseVolume:/var/lib/postgresql/data --volume /$(pwd)/backend/postgres:/docker-entrypoint-initdb.d/  -d postgres:13-alpine
  #docker network connect backendTopostgres postgres
#}

runPostgres() {
  echo "RUN postgres"
  docker run -d \
    --publish 5432:5432 \
    --name postgres \
    --env POSTGRES_USER=program \
    --env POSTGRES_PASSWORD=test \
    --env POSTGRES_DB=todo_list \
    --volume databaseVolume:/var/lib/postgresql/data \
    --volume /"$pwd"/backend/postgres:/docker-entrypoint-initdb.d/ \
    --network backendTopostgres \
    postgres:13-alpine
}


runBackend() {
  sleep 20
  echo "TODO run backend"
  docker run -d -p 8080:8080 --name backend-"$STUDENT_LABEL" \
  --env "SPRING_PROFILES_ACTIVE=docker" \
  --network backendTopostgres \
  --network frontendTobackend \
  backend:v1.0-"$STUDENT_LABEL"
  #docker network connect backendTopostgres backend-"$STUDENT_LABEL" # zadano cherez --network
  #docker network connect frontendTobackend backend-"$STUDENT_LABEL" # zadano cherez --network
  
}


runFrontend() {
  echo "RUN frontend"
  docker run -d -p 3000:80 --name frontend-"$STUDENT_LABEL" frontend:v1.0-"$STUDENT_LABEL"
  docker network connect frontendTobackend frontend-"$STUDENT_LABEL"
}

checkResult() {
  sleep 5
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
STUDENT_LABEL=nobotir

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
