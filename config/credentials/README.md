# About This Folder

This folder contains application-specific configuration in separate files per
environment:

* Development: `development.yml` (unencrypted, not in version control)
* Test: `test.yml` (unencrypted, not in version control)
* Demo: `demo.yml.enc`
* Production: `production.yml.enc`

To edit the demo and production files, use
`bin/rails credentials:edit -e <demo or production>`.

# Configuration Keys

* `aws_region`                     Region in which all AWS actions will be
                                   performed.
* `db_*`                           Database connection settings.
* `dls_aws_access_key_id`          TODO: Not sure if this is needed anymore.
* `dls_aws_secret_key`             TODO: Not sure if this is needed anymore.
* `downloader_url`                 Base URI of the Medusa Downloader.
* `downloader_user`                Medusa Downloader HTTP Digest user.
* `downloader_password`            Medusa Downloader HTTP Digest secret.
* `elasticsearch_endpoint`         Base URI of an Elasticsearch server.
* `elasticsearch_index`            Name of the Elasticsearch index or index
                                   alias.
* `iiif_url`                       IIIF Image API 2.1 endpoint.
* `image_server_api_endpoint`      Base URI of a Cantaloupe image service.
* `image_server_api_user`          Cantaloupe API HTTP Basic user.
* `image_server_api_secret`        Cantaloupe API HTTP Basic secret.
* `medusa_cache_ttl`               TTL for cached Medusa HTTP API content.
* `medusa_url`                     Base URI of the Medusa Collection Registry.
* `medusa_user`                    Medusa API username.
* `medusa_secret`                  Medusa API secret.
* `medusa_s3_bucket`               Name of the Medusa repository bucket.
* `medusa_s3_bucket_access_key_id` AWS access key ID with read-only access to
                                   medusa_s3_bucket.
* `medusa_s3_bucket_secret_key`    AWS secret access key with read-only access
                                   to medusa_s3_bucket.
* `metadata_gateway_url`           Base URI of the Metadata Gateway.
* `secret_key_base`                Required by Rails. Generate using
                                   `rails secret`.