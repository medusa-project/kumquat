FROM ruby:2.7.1-slim

ENV RAILS_ENV=test
ENV RAILS_LOG_TO_STDOUT=true
ENV SECRET_KEY_BASE=whateverdoesntmatter
# This is checked in various places to customize the application for a CI environment
# (where introducing a new Rails environment would be overkill)
ENV CI=1

RUN apt-get update && apt-get install -y --no-install-recommends \
  build-essential \
  curl \
  exiv2 \
  ffmpeg \
  git \
  libmagic-dev \
  libpq-dev \
  unzip \
  zip \
  && rm -rf /var/lib/apt/lists/*

RUN mkdir app
WORKDIR app

# Copy the Gemfile as well as the Gemfile.lock and install gems.
# This is a separate, earlier step in order to cache dependencies.
COPY Gemfile Gemfile.lock ./
RUN gem install bundler \
    && bundle config set without 'development test' \
    && bundle install --jobs 20 --retry 5

# Copy the main application, except whatever is listed in .dockerignore.
COPY . ./

RUN cp config/credentials/ci.yml config/credentials/test.yml
