#!/usr/bin/env bash

DOCKERFILE=$(cat <<HEREDOC
FROM node:latest

RUN yarn global add create-react-app
HEREDOC
)

DOCKER_COMPOSE=$(cat <<HEREDOC
version: "3"

services:
  app:
    build: .
    command:
      yarn start
    working_dir: /app
    volumes:
      - .:/app
    ports:
      - 3000:3000
HEREDOC
)

# write files
echo "$DOCKERFILE" > Dockerfile
echo "$DOCKER_COMPOSE" > docker-compose.yml

docker-compose build
docker-compose run --rm app create-react-app app
docker-compose run --rm app mv app/* . && mv app/.* . > /dev/null 2>&1
docker-compose run --rm app rm -rf app
docker-compose up
