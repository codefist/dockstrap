#!/usr/bin/env bash

DOCKERFILE=$(cat <<HEREDOC
FROM php:latest

RUN apt-get update && apt-get install -y --no-install-recommends mysql-client unzip openssl libzip-dev libsodium-dev

RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

ENV PATH="/root/.composer/vendor/bin:\$PATH"

RUN docker-php-ext-install sodium pdo_mysql mbstring zip

RUN composer global require laravel/lumen-installer
HEREDOC
)

DOCKER_COMPOSE=$(cat <<HEREDOC
version: "3"

volumes:
  mysql-data:

services:
  app:
    build:
      context: .
    volumes:
      - .:/app
    working_dir: /app
    depends_on:
      - mysql
    ports:
      - 8000:8000
    command:
      php -S 0.0.0.0:8000 -t public
    # env_file:
    #   - .env
  mysql:
    image: mysql:5.7
    environment:
      # Lumen uses homestead as default, so, why not...
      MYSQL_DATABASE: homestead
      MYSQL_ROOT_PASSWORD: secret
    volumes:
      - mysql-data:/var/lib/mysql
HEREDOC
)

# write files
echo "$DOCKERFILE" > Dockerfile
echo "$DOCKER_COMPOSE" > docker-compose.yml

docker-compose build
docker-compose run --rm --no-deps app composer create-project --prefer-dist laravel/lumen newapp && mv newapp/* newapp/.* ./
docker-compose run --rm --no-deps app rm -rf newapp
docker-compose run --rm --no-deps app ln -s vendor/bin/phpunit
