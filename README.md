This is a basic getting-started guide for developers.

# Quick Links

* [SCARS Wiki](https://wiki.illinois.edu/wiki/pages/viewpage.action?spaceKey=scrs&title=Medusa+DLS)
* [Issue tracker](https://bugs.library.illinois.edu/secure/RapidBoard.jspa?rapidView=20062)

# Dependencies

* Local read-only Medusa NCSA condo mount
    * Request from Library IT
    * sudo mount -t nfs -o ro cnfs.ncsa.illinois.edu:/condo/library /mnt/whatever
* Admin access to the public and staging DLS instances
* PostgreSQL 9.x
* Solr 5+ with a managed schema core
* [Cantaloupe](https://medusa-project.github.io/cantaloupe/) 3.3+
    * [Kakadu](http://kakadusoftware.com/downloads/) or
      [OpenJPEG](http://www.openjpeg.org) will also be required.
    * (Any other IIIF Image API 2.1 server should mostly work, but Cantaloupe
      provides some bonus features like PDF thumbnails and remote cache
      management.)
* exiv2
* ffmpeg

# Installation

## 1) Install RVM:

`$ \curl -sSL https://get.rvm.io | bash -s stable`

`$ source ~/.bash_profile`

## 2) Clone the repository:

`$ git clone https://github.com/medusa-project/PearTree.git`

`$ cd PearTree`

## 3) Install Ruby

`$ rvm install "$(< .ruby-version)" --autolibs=0`

## 4) Install Bundler

`$ gem install bundler`

## 5) Install the gems needed by the application:

`$ bundle install`

## 6) Configure the application

`$ cp config/database.template.yml config/database.yml` and edit as necessary

`$ cp config/peartree.template.yml config/peartree.yml` and edit as necessary

`$ cp config/shibboleth.template.yml config/shibboleth.yml`

## 7) Initialize the application

`$ bundle exec rake db:setup`

`$ bundle exec rake solr:update_schema`

## 8) Load some data

### Sync collections with Medusa

`$ bundle exec rake dls:collections:sync`

### Load the master element list

(From here on, we'll deal with the
[Champaign-Urbana Historic Built Environment](https://digital.library.illinois.edu/collections/81180450-e3fb-012f-c5b6-0019b9e633c5-2)
collection.)

1. Go to the [element list](https://digital.library.illinois.edu/admin/elements)
   on the production instance.
2. Click the `Export` button to export it to a file.
3. On your local instance, go to the
   [element list](http://localhost:3000/admin/elements) and import the file.
   (Log in as `admin / admin@example.org`.)

### Load the collection's metadata profile

1. Go to
   [the collection's metadata profile](https://digital.library.illinois.edu/admin/metadata-profiles/12)
   in the production instance.
2. Click the `Export` button to export it to a file.
3. On your local instance, go to the metadata profiles list and click the 
   `Import` button to import the file.

### Configure the collection

1. On your local instance, go to
   [the collection's admin view.](http:localhost/admin/collections/81180450-e3fb-012f-c5b6-0019b9e633c5-2)
2. Click `Edit`.
3. Copy the settings from the production instance:
    1. Set the File Group ID to `b3576c20-1ea8-0134-1d77-0050569601ca-6`.
    2. Set the Package Profile to "Single-Item Object."
    3. Set the Metadata Profile to the profile you just imported.
    4. Make sure it is "Published in DLS."
4. Save the collection.

### Sync the collection

1. Go to the
   [admin view of the collection](http://localhost:3000/admin/collections/81180450-e3fb-012f-c5b6-0019b9e633c5-2).
2. Click the `0 objects` button.
3. Click the `Sync` button.
4. In the `Sync Items` panel, make sure `Create` is checked, and click `Sync.`
   This will invoke a background job. Use `bundle exec rake jobs:workoff` to
   start it. Wait for it to complete.

### Import the collection's metadata

1. Go to
   [the collection's admin view](https://digital.library.illinois.edu/admin/collections/81180450-e3fb-012f-c5b6-0019b9e633c5-2)
   in production.
2. Click the `n objects` button.
3. Click `Metadata -> Export As TSV` and export all items to a file.
4. Go to
   [the same view](http://localhost:3000/admin/collections/81180450-e3fb-012f-c5b6-0019b9e633c5-2)
   on your local instance.
5. Import the TSV. This will invoke a background job. Use
   `bundle exec rake jobs:workoff` to start it. When complete, the collection
   should be fully populated with metadata.

## 9) Configure the image server

1. Make a copy of `config/cantaloupe/delegates-n.n-sample.rb` and modify the
   constants at the beginning of the file.
2. Make a copy of the sample config file supplied with the image server, and
   make the following configuration changes:

`delegate_script.enabled = true`

`delegate_script.pathname = <path to the script you just copied>`

`endpoint.api.enabled = true`

`endpoint.api.username = :image_server_api_user: from PearTree's config.yml`

`endpoint.api.secret = :image_server_api_secret: from PearTree's config.yml`

`FilesystemResolver.lookup_strategy = ScriptLookupStrategy`

Additionally, if using OpenJPEG rather than Kakadu, set
`processor.jp2 = OpenJpegProcessor`.

### Run it

`java -Dcantaloupe.config=cantaloupe.properties -jar Cantaloupe-n.n.war`

[Test it](http://localhost:8182/iiif/2/7b7e08f0-0b13-0134-1d55-0050569601ca-a/full/500,/0/default.jpg)

# Notes

## Tests

Test fixtures are based on production Medusa data.
`test/fixtures/collections.yml` contains the collections used for testing.
There are a few different ones which are used for testing different types of
content; see the index at the beginning of the file.

## Jobs

Most long-running operations are invoked in background jobs, in order to keep
the user interface responsive. After firing one of these off -- such as a sync
-- use `bundle exec rake jobs:workoff` to run it.

The job worker, [Delayed::Job](https://github.com/collectiveidea/delayed_job/),
can also run continually, using `rake jobs:work`. This is how it runs in
production, but it won't pick up code changes while running.

## Using Shibboleth locally

Log in as user `admin` and password `admin@example.org`.
