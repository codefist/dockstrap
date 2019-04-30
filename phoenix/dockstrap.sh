#!/usr/bin/env bash

DOCKERFILE=$(cat <<HEREDOC
FROM elixir

# Install hex
RUN mix local.hex --force

# Install rebar
RUN mix local.rebar --force

# Install the Phoenix framework
RUN mix archive.install hex phx_new 1.4.3 --force

# Prep node to install via apt
RUN curl -sL https://deb.nodesource.com/setup_12.x  | bash -

RUN apt-get update
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install nodejs inotify-tools gcc g++ make

WORKDIR /app
HEREDOC
)

DOCKER_COMPOSE=$(cat <<HEREDOC
version: "3"

volumes:
  pg-data:

services:
  app:
    build:
      context: .
    ports:
      - "4000:4000"
    volumes:
      - .:/app
    depends_on:
      - postgres
    command:
      mix phx.server

  postgres:
    image: postgres
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
      PGDATA: /var/lib/postgresql/data
    volumes:
      - pg-data:/var/lib/postgresql/data
HEREDOC
)

# write files
echo "$DOCKERFILE" > Dockerfile
echo "$DOCKER_COMPOSE" > docker-compose.yml

echo Enter the app name:
echo Phoenix uses a convention of
echo lower-case letters with underscores

read -p 'App Name (ex. hello_world): ' APPNAME

echo 'Y' | docker-compose run --no-deps --rm app mix phx.new . --app $APPNAME

RESULT=$?
if [ $RESULT -eq 0 ]; then
  # config dev database config for postgres service

  docker-compose run --rm --no-deps app mix deps.get
  docker-compose run --rm --no-deps app sed -i 's/localhost/postgres/g' config/dev.exs
  docker-compose run --rm --no-deps -w /app/assets app npm install && node node_modules/webpack/bin/webpack.js --mode development

  docker-compose run --rm app mix ecto.create

  # ask to bring it up now
  RESULT=$?
  if [ $RESULT -eq 0 ]; then
    docker-compose up
  fi

else
  echo failed
fi
