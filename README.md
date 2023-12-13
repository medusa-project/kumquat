Kumquat is an implementation of the
[Illinois Digital Library Service](https://digital.library.illinois.edu).

This is a getting-started guide for developers.

# Quick Links

* [SCARS Wiki](https://wiki.illinois.edu/wiki/display/scrs/DLS)
* [JIRA Project](https://bugs.library.illinois.edu/projects/DLD)

# Prerequisites

* Administrator access to the production DLS instance (in order to export data
  to import into your development instance)
* PostgreSQL >= 9.x
* An S3 bucket ([MinIO Server](https://min.io/download) will work in
  development & test)
* OpenSearch >= 1.0
    * The [ICU Analysis Plugin](https://www.elastic.co/guide/en/elasticsearch/plugins/current/analysis-icu.html)
      must also be installed.
* Cantaloupe 5.0+
    * You can install and configure this yourself, but it will be easier to run
      a [DLS image server container](https://github.com/medusa-project/dls-cantaloupe-docker)
      in Docker.
    * This will also require the
      [AWS Command Line Interface](https://aws.amazon.com/cli/) v1.x with the
      [awscli-login](https://github.com/techservicesillinois/awscli-login)
      plugin, which is needed to obtain credentials for Cantaloupe to access
      the relevant S3 buckets. (awscli-login requires v1.x of the CLI as of
      this writing, but that would be the only reason not to upgrade to v2.x.)
* exiv2 (used to extract image metadata)
* ffmpeg (used to extract video metadata)
* tesseract (used for OCR)

# Installation

## Install Kumquat
```sh
# Install rbenv
$ brew install rbenv
$ brew install ruby-build
$ brew install rbenv-gemset --HEAD
$ rbenv init
$ rbenv rehash

# Clone the repository
$ git clone https://github.com/medusa-project/kumquat.git
$ cd kumquat

# Install Ruby into rbenv
$ rbenv install "$(< .ruby-version)"

# Install Bundler
$ gem install bundler

# Install application gems
$ bundle install
```

## Create the OpenSearch index

```sh
$ bin/rails opensearch:indexes:create[my_index]
$ bin/rails opensearch:indexes:create_alias[my_index,my_index_alias]
```

## Configure the application

```sh
$ cd config/credentials
$ cp template.yml development.yml
$ cp template.yml test.yml
```
Edit both as necessary. In particular, set `opensearch_index` to
`my_index_alias` that you created above.

See the "Configuration" section later in this file for more information about
the configuration system.

## Create and seed the database

```
$ bin/rails db:setup
```

# Load some data

## Sync collections with Medusa

```sh
$ bin/rails dls:collections:sync
```

## Load the master element list

(From here on, we'll deal with the
[Champaign-Urbana Historic Built Environment](https://digital.library.illinois.edu/collections/81180450-e3fb-012f-c5b6-0019b9e633c5-2)
collection.)

1. Go to the element list on the production instance.
2. Click the Export button to export it to a file.
3. On your local instance, go to the element list and import the file.
   (Log in as `admin` / `admin@example.org`.)

## Load the collection's metadata profile

1. Go to the collection's metadata profile in the production instance.
2. Click the Export button to export it to a file.
3. On your local instance, go to the metadata profiles list and click the
   Import button to import the file.

## Configure the collection

1. On your local instance, go to the collection's admin view.
2. Click Edit.
3. Copy the settings from the production instance:
    1. Set the File Group ID to `b3576c20-1ea8-0134-1d77-0050569601ca-6`.
    2. Set the Package Profile to "Single-Item Object."
    3. Set the Metadata Profile to the profile you just imported.
    4. Make sure it is "Published in DLS."
    5. Save the collection.

## Sync the collection

1. Go to the admin view of the collection.
2. Click the "Objects" button.
3. Click the "Import" button.
4. In the "Import Items" panel, make sure "Create" is checked, and click
   "Import."
    * This will invoke a background job. Use `bin/rails jobs:workoff` to run
      it. Wait for it to complete.

## Import the collection's metadata

1. Go to the collection's admin view in production.
2. Click the "Objects" button.
3. Click "Metadata -> Export As TSV" and export all items to a file.
4. Go to the same view on your local instance.
5. Import the TSV. This will invoke a background job. Use
   `bin/rails jobs:workoff` to run it. When it finishes, the collection should
   be fully populated with metadata.

# Updating

## Update the database schema

```sh
$ bin/rails db:migrate
```

## Update the OpenSearch schema

Once created, index schemas can only be modified to a limited extent. To
migrate to an incompatible schema, the procedure would be:

1. Update the index schema in `app/search/index_schema.yml`
2. Create a new index with the new schema:
   `rails opensearch:indexes:create[new_index]`
3. Populate the new index with documents. There are a couple of ways to do
   this:
    1. If the schema change was backwards-compatible with the source documents
       added to the index, invoke
       `rails opensearch:indexes:reindex[current_index,new_index]`.
       This will reindex all source documents from the current index into the
       new index.
    2. Otherwise, reindex all database content:
       ```sh
       $ rails dls:collections:reindex
       $ rails dls:agents:reindex
       $ rails dls:items:reindex
       ```

# Tests

There are several dependent services:

* PostgreSQL
* OpenSearch
* A working [Medusa Collection Registry](https://medusa.library.illinois.edu).
  There are a lot of tests that rely on fixture data within Medusa.
  Unfortunately, production Medusa data is not stable enough to test against
  and it's hard to tailor for specific tests that require specific types of
  content. So instead, all of the tests rely on a mock of Medusa called
  [Mockdusa](https://github.com/medusa-project/mockdusa).
* A Cantaloupe image server instance.
* Three S3 buckets:
    1. One for the Cantaloupe cache.
    2. One for application data.
    3. One containing Medusa repository data. The content exposed by
       Mockdusa, above, should be available in this bucket.

Because getting all of this running locally can be a hassle, there is also a
`docker-compose.yml` file that will spin up all of the required services and
run the tests within a containerized environment:

```sh
aws login
eval $(aws ecr get-login --region us-east-2 --no-include-email --profile default)
docker-compose pull && docker-compose up --build --exit-code-from kumquat
```

# Configuration

See the class documentation in `app/config/configuration.rb` for a detailed
explanation of how the configurarion system works. The short explanation is
that the `develop` and `test` environments rely on the unencrypted
`config/credentials/develop.yml` and `test.yml` files, respectively, while the
`demo` and `production` environments rely on the `demo.yml.enc` and
`production.yml.enc` files, which are Rails 6 encrypted credentials files.

# Authorization

In the production and demo environments, authorization uses LDAP. In
development and test, there is one "canned user" for each Medusa LDAP group:

* `user`: Library Medusa Users
* `admin`: Library Medusa Admins
* `super`: Library Medusa Super Admins

Sign in with any of these using `[username]@example.org` as the password.

# Documentation

The `rake doc:generate` command invokes YARD to generate HTML documentation
for the code base.