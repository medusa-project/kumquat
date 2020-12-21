FROM ruby:2.7.1-slim

ENV RAILS_ENV=test
ENV RAILS_LOG_TO_STDOUT=true
ENV SECRET_KEY_BASE=whateverdoesntmatter
ENV CI=1

RUN apt-get update && apt-get install -y \
  build-essential \
  libmagic-dev \
  libpq-dev \
  curl \
  git \
  exiv2 \
  zip \
  ffmpeg

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
