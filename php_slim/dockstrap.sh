#!/usr/bin/env bash

DOCKERFILE=$(cat <<HEREDOC
FROM php:latest

RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

ENV PATH="/root/.composer/vendor/bin:\$PATH"

RUN apt-get update && apt-get install -y unzip zlib1g-dev libzip-dev && docker-php-ext-install zip
HEREDOC
)

DOCKER_COMPOSE=$(cat <<HEREDOC
version: "3"

services:
  app:
    build:
      context: .
    volumes:
      - .:/app
    working_dir: /app
    ports:
      - 8080:8080
    command:
      php -S 0.0.0.0:8080 -t public public/index.php
HEREDOC
)

# write files
echo "$DOCKERFILE" > Dockerfile
echo "$DOCKER_COMPOSE" > docker-compose.yml


docker-compose build
docker-compose run --rm app composer create-project slim/slim-skeleton tmp
docker-compose run --rm app rm tmp/docker-compose.yml
docker-compose run --rm app mv tmp/* . && rm -rf tmp/

docker-compose up
