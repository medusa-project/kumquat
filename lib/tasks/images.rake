namespace :images do

  desc 'Purge all images from the image server cache'
  task :purge_all => :environment do
    ImageServer.instance.purge_all_images_from_cache
  end

  desc 'Purge all images associated with an item from the image server cache'
  task :purge_item, [:uuid] => :environment do |task, args|
    item = Item.find_by_repository_id(args[:uuid])
    ImageServer.instance.purge_item_images_from_cache(item)
  end

  desc 'Purge all images associated with any item in a collection from the image server cache'
  task :purge_collection, [:uuid] => :environment do |task, args|
    col = Collection.find_by_repository_id(args[:uuid])
    ImageServer.instance.purge_collection_item_images_from_cache(col)
  end

end
