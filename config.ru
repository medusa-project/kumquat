# This file is used by Rack-based servers to start the application.

require ::File.expand_path('../config/environment', __FILE__)
require 'favorites_zip_downloader'
require 'items_zip_downloader'

map '/favorites/download' do
  run FavoritesZipDownloader.new
end
map '/items/download' do
  run ItemsZipDownloader.new
end

run Rails.application
