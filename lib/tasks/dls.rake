namespace :dls do

  namespace :agents do

    desc 'Reindex all agents'
    task :reindex => :environment do |task, args|
      # Reindex existing collections
      Agent.all.each { |agent| agent.index_in_solr }
      # Remove indexed documents whose entities have disappeared.
      # (For these, Relation will contain a string ID in place of an instance.)
      Agent.solr.all.limit(99999).select{ |a| a.to_s == a }.each do |agent_id|
        Solr.delete_by_id(agent_id)
      end
      Solr.instance.commit
    end

  end

  namespace :binaries do

    desc 'Update binaries in all collections'
    task :update => :environment do |task|
      ActiveRecord::Base.transaction do
        Collection.all.each do |collection|
          next if collection.items.count == 0
          puts collection.title
          MedusaIngester.new.update_binaries(collection)
        end
      end
      Solr.instance.commit
    end

    desc 'Update binaries in a collection'
    task :update_collection, [:uuid] => :environment do |task, args|
      collection = Collection.find_by_repository_id(args[:uuid])
      ActiveRecord::Base.transaction do
        MedusaIngester.new.update_binaries(collection)
      end
      Solr.instance.commit
    end

    desc 'Populate the sizes of all binaries'
    task :populate_byte_sizes => :environment do |task|
      Binary.uncached do
        binaries = Binary.where(byte_size: nil).
            where('repository_relative_pathname IS NOT NULL')
        count = binaries.count
        puts "#{count} binaries to update"

        binaries.find_each.with_index do |binary, index|
          puts "(#{((index / count.to_f) * 100).round(2)}%) "\
              "#{binary.repository_relative_pathname} "

          pathname = binary.absolute_local_pathname
          binary.byte_size = (pathname and File.exist?(pathname) and File.file?(pathname)) ?
              File.size(pathname) : nil
          binary.save!
        end
      end
    end

    desc 'Populate the dimensions of all binaries'
    task :populate_dimensions => :environment do |task|
      Binary.uncached do
        binaries = Binary.where('(width IS NULL OR height IS NULL) AND '\
            'repository_relative_pathname IS NOT NULL')
        count = binaries.count
        puts "#{count} binaries to update"

        binaries.find_each.with_index do |binary, index|
          puts "(#{((index / count.to_f) * 100).round(2)}%) "\
              "#{binary.repository_relative_pathname} "

          binary.read_dimensions
          binary.save!
        end
      end
    end

  end

  namespace :collections do

    desc 'Publish a collection'
    task :publish, [:uuid] => :environment do |task, args|
      Collection.find_by_repository_id(args[:uuid]).
          update!(published: true, published_in_dls: true)
    end

    desc 'Reindex all collections'
    task :reindex => :environment do |task, args|
      reindex_collections
      Solr.instance.commit
    end

    desc 'Sync collections from Medusa'
    task :sync => :environment do |task|
      SyncCollectionsJob.new.perform_in_foreground
    end

  end

  namespace :images do

    desc 'Purge an item\'s images from the image server cache'
    task :purge, [:uuid] => :environment do |task, args|
      item = Item.find_by_repository_id(args[:uuid])
      item.purge_cached_images
    end

  end

  namespace :items do

    desc 'Delete all items from a collection'
    task :purge_collection, [:uuid] => :environment do |task, args|
      ActiveRecord::Base.transaction do
        Item.where(collection_repository_id: args[:uuid]).destroy_all
      end
      Solr.instance.commit
    end

    desc 'Reindex all items'
    task :reindex => :environment do |task, args|
      num_entities = Item.count
      # Item.uncached{} in conjunction with find_each() circumvents ActiveRecord
      # caching that could lead to memory exhaustion.
      Item.uncached do
        Item.all.find_each.with_index do |item, index|
          item.index_in_solr
          puts "reindex: #{((index / num_entities.to_f) * 100).round(2)}%"
        end
      end
      Solr.instance.commit
    end

    desc 'Reindex items in a collection'
    task :reindex_collection, [:uuid] => :environment do |task, args|
      Item.where(collection_repository_id: args[:uuid]).each do |item|
        item.index_in_solr
      end
      Solr.instance.commit
    end

    desc 'Delete all item Solr documents in a collection'
    task :clear_collection_index, [:uuid] => :environment do |task, args|
      Solr.instance.delete_by_query("#{Item::SolrFields::COLLECTION}:#{args[:uuid]}")
      Solr.instance.commit
    end

    desc 'Sync items from Medusa (modes: create_only, update_binaries, delete_missing)'
    task :sync, [:collection_uuid, :mode] => :environment do |task, args|
      SyncItemsJob.new(args[:collection_uuid], args[:mode],
                       extract_metadata: false).perform_in_foreground
    end

    desc 'Update items from a TSV file'
    task :update_from_tsv, [:pathname] => :environment do |task, args|
      ImportItemsFromTsvJob.new(args[:pathname]).perform_in_foreground
    end

  end

  namespace :tasks do

    desc 'Clear all tasks'
    task :clear => :environment do |task, args|
      Task.destroy_all
    end

    desc 'Clear running tasks'
    task :clear_running => :environment do |task, args|
      Task.where(status: Task::Status::RUNNING).destroy_all
    end

    desc 'Clear waiting tasks'
    task :clear_waiting => :environment do |task, args|
      Task.where(status: Task::Status::WAITING).destroy_all
    end

  end

  def reindex_collections
    # Reindex existing collections
    Collection.all.each { |col| col.index_in_solr }
    # Remove indexed documents whose entities have disappeared.
    # (For these, Relation will contain a string ID in place of an instance.)
    Collection.solr.all.limit(99999).select{ |c| c.to_s == c }.each do |col_id|
      Solr.delete_by_id(col_id)
    end
  end

end
