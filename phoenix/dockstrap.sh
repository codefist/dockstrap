#!/usr/bin/env bash

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
