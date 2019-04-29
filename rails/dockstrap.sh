#!/usr/bin/env bash

# FILE CONTENTS:
GEMFILE=$(cat <<HEREDOC
source 'https://rubygems.org'
gem 'rails', '~>5'
HEREDOC
)

DATABASE_YML=$(cat <<HEREDOC
default: &default
  adapter: postgresql
  encoding: unicode
  host: postgres
  username: postgres
  password: postgres
  pool: 5
development:
  <<: *default
  database: myapp_development
test:
  <<: *default
  database: myapp_test
HEREDOC
)

ENTRYPOINT=$(cat <<HEREDOC
#!/bin/bash
set -e
rm -f /myapp/tmp/pids/server.pid
exec "$@"
HEREDOC
)

DOCKERFILE=$(cat <<HEREDOC
FROM ruby:2.5
RUN apt-get update -qq && apt-get install -y nodejs postgresql-client
RUN mkdir /myapp
WORKDIR /myapp
COPY Gemfile /myapp/Gemfile
COPY Gemfile.lock /myapp/Gemfile.lock

ENV BUNDLE_PATH /bundle
ENV BUNDLE_JOBS 2

RUN bundle install
COPY . /myapp

# Add a script to be executed every time the container starts.
COPY entrypoint.sh /usr/bin/
RUN chmod +x /usr/bin/entrypoint.sh
ENTRYPOINT ["entrypoint.sh"]
EXPOSE 3000

# Start the main process.
CMD ["rails", "server", "-b", "0.0.0.0"]
HEREDOC
)

DOCKER_COMPOSE=$(cat <<HEREDOC
version: "3"

volumes:
  pg-data:
  bundle:

services:
  web:
    build: .
    command: bash -c "rm -f tmp/pids/server.pid && bundle exec rails s -p 3000 -b '0.0.0.0'"
    volumes:
      - .:/myapp
      - bundle:/bundle
    ports:
      - "3000:3000"
    depends_on:
      - postgres

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

# write the files
echo "$ENTRYPOINT" > entrypoint.sh
echo "$GEMFILE" > Gemfile
echo "$DOCKERFILE" > Dockerfile
echo "$DOCKER_COMPOSE" > docker-compose.yml
touch Gemfile.lock

docker-compose run --no-deps --rm web bundle exec rails new . --force --database=postgresql
docker-compose run --no-deps --rm web echo "$DATABASE_YML" > config/database.yml
docker-compose run --rm web bundle exec rails db:create
docker-compose up
