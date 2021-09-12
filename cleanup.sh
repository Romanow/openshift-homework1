#!/bin/sh

BASE_LABEL=homework1
STUDENT_LABEL=pershin

docker run -d \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -p 9000:8080 \
  quay.io/testcontainers/ryuk

printf "label=%s" "$BASE_LABEL-$STUDENT_LABEL" | nc localhost 9000