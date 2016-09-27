# This file is used by Rack-based servers to start the application.

require ::File.expand_path('../config/environment', __FILE__)
require 'zip_downloader'

map '/items/download' do
  run ZipDownloader.new
end

run Rails.application
