#!/bin/sh

docker compose rm -f kumquat
docker compose up --build --exit-code-from kumquat
