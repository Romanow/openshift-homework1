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
docker network create --label $BASE_LABEL-$STUDENT_LABEL backend-postgres
docker network create --label $BASE_LABEL-$STUDENT_LABEL frontend-backend
}

createVolume() {
docker volume create --label $BASE_LABEL-$STUDENT_LABEL --name postgres
}

runPostgres() {
docker run -d --name postgres \
	-p 5432:5432 \
	-e POSTGRES_USER=test \
	-e POSTGRES_PASSWORD=test \
	-e POSTGRES_DB=example \
	-l $BASE_LABEL-$STUDENT_LABEL \
	-v postgres
	postgres:13
}

runBackend() {
 docker run -d --name backend-$BASE_LABEL-$STUDENT_LABEL \
	 -p 8080:8080 \
	 -e SPRING_PROFILES_ACTIVE=docker \
	 -l $BASE_LABEL-$STUDENT_LABEL \
	 --network backend-postgres \
	 --network frontend-backend \
	 backend
}

runFrontend() {
	docker run -d name -frontend-$BASE_LABEL-$STUDENT_LABEL \
		-p 3000:80 \
		-l $BASE_LABEL-$STUDENT_LABEL \
		--network frontend-backend \
		frontend
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
STUDENT_LABEL=slepenkov

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
