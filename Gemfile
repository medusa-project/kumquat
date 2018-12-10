source 'https://rubygems.org'

gem 'rails', '5.1.6'

gem 'activemodel-serializers-xml'
gem 'bootstrap-sass', '~> 3.3.6'
gem 'browser'
gem 'curb'
gem 'daemons' # enables bin/delayed_job start/stop
gem 'delayed_job_active_record'
gem 'draper' # Provides decorators
gem 'elasticsearch-model', '~> 5.0'
gem 'font-awesome-sass', '~> 4.7.0'
gem 'httpclient'
gem 'jbuilder', '~> 2.0' # JSON DSL: https://github.com/rails/jbuilder
gem 'jquery-rails'
gem 'js_cookie_rails'
gem 'local_time'
gem 'mime-types', '~> 2.6'
gem 'netaddr'
gem 'nokogiri', '~> 1.8.2'
gem 'omniauth'
gem 'omniauth-shibboleth'
gem 'pg'
# Used to generate PDFs of compound objects. This commit fixes a frequent
# warning about an already-initialized constant.
# See: https://github.com/prawnpdf/prawn/issues/1024
gem 'prawn', git: 'https://github.com/prawnpdf/prawn.git', ref: '9250c8675342872603332784f77263fcb1cf72a2'
gem 'rails_autolink'
gem 'sass-rails', '~> 5.0'
gem 'tzinfo-data'
gem 'uglifier', '>= 1.3.0' # JavaScript asset compressor

group :development do
  gem 'capistrano-bundler'
  gem 'capistrano-rails'
  gem 'capistrano-rvm'
  gem 'puma' # supports chunked/streaming responses
  gem 'rails-erd', require: false # generate a model diagram with `bundle exec erd`
end

group :production do
  gem 'passenger'
end
