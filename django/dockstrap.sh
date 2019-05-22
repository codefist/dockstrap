#!/usr/bin/env bash

DOCKERFILE=$(cat <<HEREDOC
FROM python:3
ENV PYTHONUNBUFFERED 1
RUN mkdir /code
WORKDIR /code
COPY requirements.txt /code/
RUN pip install -r requirements.txt
COPY . /code/
HEREDOC
)

DOCKER_COMPOSE=$(cat <<HEREDOC
version: "3"

volumes:
  pg-data:

services:
  web:
    build: .
    command: python manage.py runserver 0.0.0.0:8000
    volumes:
      - .:/code
    ports:
      - "8000:8000"
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

REQUIREMENTS=$(cat <<HEREDOC
Django>=2.0,<3.0
psycopg2>=2.7,<3.0
HEREDOC
)

DATABASES=$(cat <<HEREDOC
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': 'postgres',
        'PASSWORD': 'postgres',
        'USER': 'postgres',
        'HOST': 'postgres',
        'PORT': 5432,
    }
}
HEREDOC
)

# write files
echo "$DOCKERFILE" > Dockerfile
echo "$DOCKER_COMPOSE" > docker-compose.yml
echo "$REQUIREMENTS" > requirements.txt
echo "$DATABASES" > databases


echo Enter the PROJECT name:
echo Use lower-case letters with no spaces

read -p 'Project Name (ex. helloworld): ' PROJECTNAME

docker-compose run --rm --no-deps web django-admin startproject $PROJECTNAME .

RESULT=$?
if [ $RESULT -eq 0 ]; then
  # config dev database config for postgres service
  docker-compose run --rm web cat databases >> $PROJECTNAME/settings.py

  # ask to bring it up now
  RESULT=$?
  if [ $RESULT -eq 0 ]; then
    docker-compose up
  fi

else
  echo failed
fi
