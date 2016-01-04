# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = '1.0'

# Add additional assets to the asset load path
Dir.glob(File.join(Rails.root, 'local', 'themes', '*', 'assets', 'images')).each do |path|
  Rails.application.config.assets.paths << path
end
Dir.glob(File.join(Rails.root, 'local', 'themes', '*', 'assets', 'stylesheets')).each do |path|
  Rails.application.config.assets.paths << path
end

Rails.application.config.assets.paths << Rails.root.join('app', 'assets', 'fonts')

# Precompile additional assets.
# application.js, application.css, and all non-JS/CSS in app/assets folder are already added.
# Rails.application.config.assets.precompile += %w( search.js )

Rails.application.config.assets.precompile += %w(admin.css)
Rails.application.config.assets.precompile << /\.(?:png|jpg|jpeg|gif)\z/
