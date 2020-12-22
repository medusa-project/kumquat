##
# This Dockerfile creates directories for each bucket needed by our
# docker-compose.yml.
#

FROM minio/minio:latest

ENV MINIO_ACCESS_KEY=MinioUser
ENV MINIO_SECRET_KEY=OpenSesame

RUN mkdir -p /buckets/kumquat /buckets/medusa /buckets/cantaloupe

# Minio doesn't support buckets across filesystems, hence we can't use a bind
# mount here. The implication of this is that, for the tests that need to
# rearrange Medusa content, they must do so via S3 rather than via moving
# around the underlying files.
COPY ./docker/mockdusa/content/ /buckets/medusa/

ENTRYPOINT ["minio", "server", "/buckets", "--address", "0.0.0.0:9000"]
