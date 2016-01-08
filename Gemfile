source 'https://rubygems.org'

gem 'rails', '4.2.5'

gem 'bcrypt', '~> 3.1.7' # used by ActiveModel has_secure_password
gem 'bootstrap-sass', '~> 3.3.6'
#gem 'coffee-rails', '~> 4.1.0'
gem 'daemons' # enables bin/delayed_job start/stop
gem 'delayed_job_active_record'
gem 'font-awesome-sass', '~> 4.5.0'
gem 'httpclient', git: 'git://github.com/medusa-project/httpclient.git'
gem 'jbuilder', '~> 2.0' # JSON DSL: https://github.com/rails/jbuilder
gem 'jquery-cookie-rails'
gem 'jquery-rails'
gem 'local_time'
gem 'mime-types', '~> 2.6'
gem 'omniauth'
gem 'omniauth-password', git: 'git://github.com/wearepistachio/omniauth-password.git'
gem 'pg'
gem 'rails_autolink'
gem 'rsolr'
gem 'sass-rails', '~> 5.0'
#gem 'sdoc', '~> 0.4.0', group: :doc # bundle exec rake doc:rails generates the API under doc/api.
#gem 'therubyracer', platforms: :ruby # See https://github.com/rails/execjs#readme for more supported runtimes
gem 'uglifier', '>= 1.3.0' # JavaScript asset compressor
gem 'yomu' # text extraction from PDF, .docx, etc.

group :development do
  gem 'capistrano-bundler'
  gem 'capistrano-rails'
  gem 'capistrano-rvm'
  gem 'puma' # puma supports chunked responses
end

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  #gem 'byebug'
  # Access an IRB console on exception pages or by using <%= console %> in views
  #gem 'web-console', '~> 2.0'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  #gem 'spring'
end

group :production do
  gem 'passenger'
end
