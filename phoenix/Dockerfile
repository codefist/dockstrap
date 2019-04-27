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
