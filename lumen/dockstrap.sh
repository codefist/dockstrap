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
      MYSQL_DATABASE: app
      MYSQL_ROOT_PASSWORD: secret
    volumes:
      - mysql-data:/var/lib/mysql
HEREDOC
)

MAKEFILE=$(cat <<HEREDOC
test:
	docker-compose run --rm app ./phpunit
HEREDOC
)

DOTENV=$(cat <<HEREDOC
APP_NAME=Lumen
APP_ENV=local
APP_KEY=
APP_DEBUG=true
APP_URL=http://localhost
APP_TIMEZONE=UTC

LOG_CHANNEL=stack
LOG_SLACK_WEBHOOK_URL=

DB_CONNECTION=mysql
DB_HOST=mysql
DB_PORT=3306
DB_DATABASE=app
DB_USERNAME=root
DB_PASSWORD=secret

CACHE_DRIVER=file
QUEUE_CONNECTION=sync
HEREDOC
)

# write files
echo "$DOCKERFILE" > Dockerfile
echo "$DOCKER_COMPOSE" > docker-compose.yml
echo "$MAKEFILE" > makefile
echo "$DOTENV" > dotenv

docker-compose build
docker-compose run --rm --no-deps app composer create-project --prefer-dist laravel/lumen newapp && mv newapp/* newapp/.* ./
docker-compose run --rm --no-deps app rm -rf newapp
docker-compose run --rm --no-deps app ln -s vendor/bin/phpunit
docker-compose run --rm --no-deps app mv dotenv .env

echo "####################################"
echo "## All done - running 'make test' ##"
echo "####################################"
make test
