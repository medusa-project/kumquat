Kumquat is an implementation of the
[Illinois Digital Special Collections Service](https://digital.library.illinois.edu).

This is a getting-started guide for developers.

# Quick Links

* [SCARS Wiki](https://wiki.library.illinois.edu/scars/Production_Services/Illinois_Digital_Library/DLS)
* [GitHub Issues Project](https://github.com/medusa-project/digital-library-issues/issues)
    * [Project Board](https://github.com/orgs/medusa-project/projects/2)

# Local Development Prerequisites

* Administrator access to the production DSC instance (in order to export data
  to import into your development instance)
* PostgreSQL >= 9.x
* An S3 server (MinIO Server, s3proxy, and SeaweedFS will all work in
  development & test)
* OpenSearch >= 1.0
    * The `analysis-icu` plugin must also be installed.
* Cantaloupe 5.0+
    * You can install and configure this yourself, but it will be easier to run
      a [DSC image server container](https://github.com/medusa-project/dls-cantaloupe-docker)
      in Docker.
    * This will also require the
      [AWS Command Line Interface](https://aws.amazon.com/cli/) v1.x with the
      [awscli-login](https://github.com/techservicesillinois/awscli-login)
      plugin, which is needed to obtain credentials for Cantaloupe to access
      the relevant S3 buckets. (awscli-login requires v1.x of the CLI as of
      this writing, but that would be the only reason not to upgrade to v2.x.
      It's also possible to install 1.x, then rename the `aws` executable to
      something like `aws-v1`, then install 2.x, and only use `aws-v1 login`
      for logins.)
* exiv2 (used to extract image metadata)
* ffmpeg (used to extract video metadata)
* tesseract (used for OCR)

# Installation

## Install Kumquat
```sh
# Install rbenv
$ brew install rbenv
$ brew install ruby-build
$ brew install rbenv-gemset
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

## Configure Opensearch

### Support a single node

Uncomment `discovery.type: single-node` in `config/opensearch.yml`. Also add
the following lines:

```yaml
plugins.security.disabled: true
plugins.index_state_management.enabled: false
reindex.remote.whitelist: "localhost:*"
```

### Install the analysis-icu plugin

```sh
$ bin/opensearch-plugin install analysis-icu
```

### Start OpenSearch
```sh
$ bin/opensearch
```

To confirm that it's running, try to access
[http://localhost:9200](http://localhost:9200).

## Configure Kumquat

Obtain `demo.key` and `production.key` from a team member and put them in
`config/credentials`. Then:

```sh
$ cd config/credentials
$ cp template.yml development.yml
$ cp template.yml test.yml
```
Edit both as necessary.

See the "Configuration" section later in this file for more information about
the configuration system.

## Create an OpenSearch index for Kumquat

```sh
$ bin/rails "opensearch:indexes:create[kumquat_development_blue]"
$ bin/rails "opensearch:indexes:create_alias[kumquat_development_blue,kumquat_development]"
```

## Create and seed the database

```
$ bin/rails db:setup
```

# Load some data

## Import collections from Medusa

Run this command **TWICE**:

```sh
$ bin/rails collections:sync
```

After the second invocation has completed, it only has to be run once from now
on.

## Load the master element list

(From here on, we'll deal with the
[Champaign-Urbana Historic Built Environment](https://digital.library.illinois.edu/collections/81180450-e3fb-012f-c5b6-0019b9e633c5-2)
collection.)

1. Go to the element list on the production instance.
2. Click the Export button to export it to a file.
3. On your local instance, go to the element list and import the file.
   (Log in as `super` / `super@example.org`.)

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
   "Import." This will invoke a background job. Wait for it to complete.

## Import the collection's metadata

1. Go to the collection's admin view in production.
2. Click the "Objects" button.
3. Click "Metadata -> Export As TSV" and export all items to a file.
4. Go to the same view on your local instance.
5. Import the TSV. This will invoke a background job. When it finishes, the
   collection should be fully populated with metadata.

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
   `rails "opensearch:indexes:create[new_index]"`
3. Populate the new index with documents. There are a couple of ways to do
   this:
    1. If the schema change was backwards-compatible with the source documents
       added to the index, invoke
       `rails "opensearch:indexes:reindex[current_index,new_index]"`.
       This will reindex all source documents from the current index into the
       new index.
    2. Otherwise, reindex all database content:
       ```sh
       $ rails collections:reindex
       $ rails agents:reindex
       $ rails items:reindex
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

Due to the hassle of getting all of this running locally, there is also a
`docker-compose.yml` file that will spin up all of the required services and
run the tests within a containerized environment:

```sh
aws login
eval $(aws ecr get-login --region us-east-2 --no-include-email --profile default)
docker-compose pull && docker-compose up --build --exit-code-from kumquat
```

# Configuration

See the class documentation in `app/config/configuration.rb` for a detailed
explanation of how the configuration system works. The short explanation is
that the `develop` and `test` environments rely on the unencrypted
`config/credentials/develop.yml` and `test.yml` files, respectively, while the
`demo` and `production` environments rely on the `demo.yml.enc` and
`production.yml.enc` files, which are Rails 6 encrypted credentials files.

# Authorization

In the production and demo environments, authorization uses the campus Active
Directory via LDAP. In development and test, there is one "canned user" for
each Medusa AD group:

* `user`: Library Medusa Users
* `admin`: Library Medusa Admins
* `super`: Library Medusa Super Admins

Sign in with any of these using `[username]@example.org` as the password.

# Documentation

The `rake doc:generate` command invokes YARD to generate HTML documentation
for the code base.
