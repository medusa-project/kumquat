source 'https://rubygems.org'

gem 'activemodel-serializers-xml'
gem 'aws-sdk-s3', '~> 1.8'
gem 'bootstrap', '~> 4.3.1'
gem 'browser'
gem 'curb'
gem 'daemons' # enables bin/delayed_job start/stop
gem 'delayed_job_active_record'
gem 'draper' # Provides decorators
gem 'httpclient'
gem 'jbuilder', '~> 2.0' # JSON DSL: https://github.com/rails/jbuilder
gem 'jquery-rails'
gem 'js_cookie_rails'
gem 'local_time'
gem 'mimemagic'
gem 'marc-dates', git: 'https://github.com/medusa-project/marc-dates.git'
gem 'mime-types', '~> 2.6'
gem 'mini_racer'
gem 'netaddr'
gem 'omniauth'
gem 'omniauth-shibboleth'
gem 'pg'
# Used to generate PDFs of compound objects. This commit fixes a frequent
# warning about an already-initialized constant.
# See: https://github.com/prawnpdf/prawn/issues/1024
gem 'prawn', git: 'https://github.com/prawnpdf/prawn.git', ref: '9250c8675342872603332784f77263fcb1cf72a2'
gem 'rails', '5.2.3'
gem 'rails_autolink'
gem 'sassc'
gem 'scars-bootstrap-theme', git: 'https://github.com/medusa-project/scars-bootstrap-theme.git'
gem 'tzinfo-data'
gem 'uglifier', '>= 1.3.0' # JavaScript asset compressor

group :development do
  gem 'capistrano-bundler'
  gem 'capistrano-rails'
  gem 'capistrano-rbenv'
  gem 'puma'
  gem 'rails-erd', require: false # generate a model diagram with `bundle exec erd`
  gem 'yard'
end

group :production do
  gem 'passenger'
end
