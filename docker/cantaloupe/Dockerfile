# Cantaloupe is x86-only until the Kakadu native lib is compiled for ARM
FROM --platform=linux/amd64 eclipse-temurin:11

# used in delegates.rb
ENV MEDUSA_URL=http://mockdusa:4567
ENV MEDUSA_USER=medusa
ENV MEDUSA_SECRET=secret
ENV S3SOURCE_BUCKET_NAME=medusa

ARG version=5.0.5
ARG home=/home/cantaloupe

RUN apt-get update && apt-get install -y --no-install-recommends \
    unzip \
    wget \
  && rm -rf /var/lib/apt/lists/*

RUN mkdir -p $home/tmp
WORKDIR $home

# Download and extract the Cantaloupe archive
RUN wget https://github.com/cantaloupe-project/cantaloupe/releases/download/v$version/cantaloupe-$version.zip \
    && unzip cantaloupe-$version.zip \
    && mv cantaloupe-$version/cantaloupe-$version.jar cantaloupe-$version/cantaloupe.jar \
    && mv cantaloupe-$version cantaloupe \
    && rm cantaloupe-$version.zip

# Install KakaduNativeProcessor & TurboJpegProcessor dependencies
RUN cp cantaloupe/deps/Linux-x86-64/lib/* /usr/lib

COPY ./docker/cantaloupe/cantaloupe.properties ./cantaloupe.properties
COPY ./docker/cantaloupe/delegates.rb ./delegates.rb

ENTRYPOINT ["java", "-Dcantaloupe.config=cantaloupe.properties", \
    "-XX:MaxRAMPercentage=65", \
    "-jar", "cantaloupe/cantaloupe.jar"]
