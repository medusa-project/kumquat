This is a basic getting-started guide for developers. All other documentation
resides in the
[SCARS Wiki](https://wiki.illinois.edu/wiki/pages/viewpage.action?spaceKey=scrs&title=Medusa+DLS).

# Dependencies

* Local read-only NCSA condo mount
* PostgreSQL 9.x
* Solr 5+ with a managed schema core
* [Cantaloupe](https://medusa-project.github.io/cantaloupe/) 3.3+
    * (Any other Image API 2.1 server will mostly work, but Cantaloupe provides
    some helpful features for remote cache management.)
* exiv2

# Installation

## 1) Clone the repository:

`$ git clone https://github.com/medusa-project/PearTree.git`

`$ cd PearTree`

## 2) Install RVM:

`$ \curl -sSL https://get.rvm.io | bash -s stable`

`$ source ~/.bash_profile`

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

# Usage Notes

## Jobs

Most long-running operations are invoked in background jobs, in order to keep
the user interface responsive. After firing one of these off -- such as a sync
-- use `bundle exec rake jobs:workoff` to start it.

## Using Shibboleth locally

Log in using user `admin` and password `admin@example.org`.

# Development Notes

## Branching

This project uses the Gitflow workflow with the following exceptions:

* There is no `hotfixes` branch; fixes are applied directly to `master` and
  merged back into `develop`.
* Tags are not used.