#!/bin/sh

# Log into ECR into order to pull the mockdusa image
eval $(aws ecr get-login --region us-east-2 --no-include-email --profile default)

docker compose rm -f kumquat
docker compose up --build --exit-code-from kumquat
