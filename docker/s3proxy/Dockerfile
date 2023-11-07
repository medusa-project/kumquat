FROM eclipse-temurin:17

RUN mkdir -p /buckets/kumquat /buckets/medusa /buckets/cantaloupe \
    && wget https://github.com/gaul/s3proxy/releases/download/s3proxy-2.1.0/s3proxy \
    && chmod +x s3proxy

# N.B.: for tests that need to rearrange Medusa content, they must do so via S3
# rather than via moving around the underlying files.
COPY ./docker/mockdusa/content/ /buckets/medusa/
COPY ./docker/s3proxy/config.properties ./config.properties

EXPOSE 9000

ENTRYPOINT ["./s3proxy", "--properties", "config.properties"]
