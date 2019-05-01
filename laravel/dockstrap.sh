#!/usr/bin/env bash

DOCKERFILE=$(cat <<HEREDOC
FROM php:7.3.3

RUN apt-get update && apt-get install -y libpng-dev libmcrypt-dev mysql-client imagemagick libicu-dev zip libzip-dev

RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

ENV PATH="/root/.composer/vendor/bin:\$PATH"

RUN docker-php-ext-install exif zip gd pdo_mysql intl bcmath

RUN composer global require laravel/installer
HEREDOC
)

DOCKER_COMPOSE=$(cat <<HEREDOC
version: "3"

volumes:
  pg-data:

services:
  node:
    image: node
    volumes:
      - .:/root
    command:
      npm run watch
    working_dir: /root
  app:
    build:
      context: .
    volumes:
      - .:/var/www
    working_dir: /var/www
    depends_on:
      - postgres
    ports:
      - "9000:9000"
    command:
      php artisan serve --host=0.0.0.0 --port=9000
    # env_file:
    #   - .env
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

docker-compose run --rm --no-deps app laravel new --force .
docker-compose run --rm node npm install

docker-compose up
