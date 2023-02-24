source 'https://rubygems.org'

# Needs to match the version in .ruby-version and Dockerfile
ruby '3.0.3'

gem 'autoprefixer-rails'
gem 'aws-sdk-s3', '~> 1'
gem 'aws-sdk-lambda', '~> 1'
gem 'draper' # Provides decorators
gem "font-awesome-sass", "~> 5.6" # Provides all of our icons
gem 'good_job'
gem 'haml'
gem 'httpclient'
gem 'jbuilder' # JSON DSL: https://github.com/rails/jbuilder
gem 'jquery-rails'
gem 'js_cookie_rails'
gem 'local_time'
gem 'mimemagic'
gem 'marc-dates', git: 'https://github.com/medusa-project/marc-dates.git'
gem 'medusa-client', git: 'https://github.com/medusa-project/medusa-client.git', tag: 'v1.2.0'
gem 'mini_racer', '~> 0.4'
gem 'netaddr', '~> 2'
gem 'omniauth'
gem 'omniauth-shibboleth'
gem 'pg', '~> 1.2'
# Used to generate PDFs of compound objects.
gem 'prawn'
gem 'puma', '~> 5'
gem 'rails', '~> 7.0'
gem 'rails_autolink'
gem 'sassc'
gem 'scars-bootstrap-theme', git: 'https://github.com/medusa-project/scars-bootstrap-theme.git',
    branch: 'release/bootstrap-4.4'
#gem 'scars-bootstrap-theme', path: '../scars-bootstrap-theme'
gem 'sprockets-rails'
gem 'uglifier', '>= 1.3.0' # JavaScript asset compressor
gem 'uiuc_lib_ad', git: 'https://github.com/UIUCLibrary/uiuc_lib_ad.git'
gem 'webrick' # Rails complains if this isn't available (maybe a bug in 6.1.4.4)

group :development do
  gem 'capistrano-bundler'
  gem 'capistrano-rails'
  gem 'capistrano-rbenv'
  gem 'rails-erd', require: false # generate a model diagram with `bundle exec erd`
  gem 'yard'
end

group :production do
  gem "omniauth-rails_csrf_protection"
  gem 'yarn' # capistrano seems to want this as of Rails 6.1
end
