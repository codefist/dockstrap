#!/usr/bin/env bash

DOCKERFILE=$(cat <<HEREDOC
FROM php:latest

RUN apt-get update && apt-get install -y --no-install-recommends libpng-dev libmcrypt-dev mysql-client imagemagick libicu-dev unzip libzip-dev

RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

ENV PATH="/root/.composer/vendor/bin:\$PATH"

RUN docker-php-ext-install exif zip gd pdo_mysql intl bcmath

RUN composer global require laravel/installer
HEREDOC
)

POSTGRES_CONFIG=$(cat <<HEREDOC

DB_CONNECTION=pgsql
DB_HOST=postgres
DB_PORT=5432
DB_DATABASE=pg
DB_USERNAME=pg
DB_PASSWORD=pg
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
      - .:/code
    command:
      npm run watch
    working_dir: /code
  app:
    build:
      context: .
    volumes:
      - .:/app
    working_dir: /app
    depends_on:
      - postgres
    ports:
      - 9000:9000
    command:
      php artisan serve --host=0.0.0.0 --port=9000
    # env_file:
    #   - .env
  postgres:
    image: postgres
    environment:
      POSTGRES_USER: pg
      POSTGRES_DB: pg
      POSTGRES_PASSWORD: pg
      PGDATA: /var/lib/postgresql/data
    volumes:
      - pg-data:/var/lib/postgresql/data
HEREDOC
)

# write files
echo "$DOCKERFILE" > Dockerfile
echo "$DOCKER_COMPOSE" > docker-compose.yml

docker-compose build
docker-compose run --rm --no-deps app laravel new --force .
docker-compose run --rm --no-deps app sed '/DB_CONNECTION=mysql/,/DB_PASSWORD=/d' .env > .newenv
echo "$POSTGRES_CONFIG" >> .newenv
mv .newenv .env
docker-compose run --rm node npm install

docker-compose up
