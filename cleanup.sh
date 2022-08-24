#!/bin/sh

docker rm -f backend frontend postgres
docker network rm network-backend network-frontend
docker volume rm postgres-data