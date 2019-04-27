#!/usr/bin/env bash

echo Enter the PROJECT name:
echo Use lower-case letters with no spaces

read -p 'Project Name (ex. helloworld): ' PROJECTNAME

docker-compose run --rm --no-deps web django-admin startproject $PROJECTNAME .

RESULT=$?
if [ $RESULT -eq 0 ]; then
  # config dev database config for postgres service
  docker-compose run --rm --no-deps web cat databases >> $PROJECTNAME/settings.py

  # ask to bring it up now
  RESULT=$?
  if [ $RESULT -eq 0 ]; then
    docker-compose up
  fi

else
  echo failed
fi
