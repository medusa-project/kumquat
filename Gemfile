source 'https://rubygems.org'

# Needs to match the version in .ruby-version and Dockerfile
ruby '2.7.1'

gem 'autoprefixer-rails'
gem 'aws-sdk-s3', '~> 1'
gem 'daemons' # enables bin/delayed_job start/stop
gem 'delayed_job_active_record'
gem 'draper' # Provides decorators
gem "font-awesome-sass", "~> 5.6" # Provides all of our icons
gem 'haml'
gem 'httpclient'
gem 'jbuilder' # JSON DSL: https://github.com/rails/jbuilder
gem 'jquery-rails'
gem 'js_cookie_rails'
gem 'local_time'
gem 'mimemagic'
gem 'marc-dates', git: 'https://github.com/medusa-project/marc-dates.git'
gem 'medusa-client', git: 'https://github.com/medusa-project/medusa-client.git', tag: 'v1.1.0'
gem 'mini_racer'
gem 'netaddr', '~> 2'
gem 'omniauth'
gem 'pg'
# Used to generate PDFs of compound objects. This commit fixes a frequent
# warning about an already-initialized constant.
# See: https://github.com/prawnpdf/prawn/issues/1024
gem 'prawn', git: 'https://github.com/prawnpdf/prawn.git', ref: '9250c8675342872603332784f77263fcb1cf72a2'
gem 'puma'
gem 'rails', '6.1.0'
gem 'rails_autolink'
gem 'sassc'
gem 'scars-bootstrap-theme', git: 'https://github.com/medusa-project/scars-bootstrap-theme.git',
    branch: 'release/bootstrap-4.4'
#gem 'scars-bootstrap-theme', path: '../scars-bootstrap-theme'
gem 'uglifier', '>= 1.3.0' # JavaScript asset compressor

group :development do
  gem 'capistrano-bundler'
  gem 'capistrano-rails'
  gem 'capistrano-rbenv'
  gem 'rails-erd', require: false # generate a model diagram with `bundle exec erd`
  gem 'yard'
end

group :production do
  gem "omniauth-rails_csrf_protection"
  gem 'omniauth-shibboleth'
  gem 'yarn' # capistrano seems to want this as of Rails 6.1
end
