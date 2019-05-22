#!/usr/bin/env bash

DOCKERFILE=$(cat <<HEREDOC
FROM elixir:latest
HEREDOC
)

DOCKER_COMPOSE=$(cat <<HEREDOC
version: "3"

services:
  elixir:
    build:
      context: .
    volumes:
      - .:/code
    command: bash
    working_dir: /code
HEREDOC
)

# write files
echo "$DOCKERFILE" > Dockerfile
echo "$DOCKER_COMPOSE" > docker-compose.yml

echo Enter the initial module name:
echo Elixir module format examples: Foo, FooBar, Foo.Bar
read -p 'mix new . --module ' MODULENAME

docker-compose run --rm elixir mix new . --module $MODULENAME
docker-compose run --rm elixir mix test
docker-compose run --rm elixir
