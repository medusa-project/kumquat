namespace :dls do

  namespace :agents do

    desc 'Reindex all agents'
    task :reindex => :environment do |task, args|
      reindex_agents
    end

  end

  namespace :binaries do

    desc 'Recreate binaries in all collections'
    task :recreate => :environment do |task|
      ActiveRecord::Base.transaction do
        Collection.all.each do |collection|
          next if collection.items.count == 0
          puts collection.title
          MedusaIngester.new.recreate_binaries(collection)
        end
      end
    end

    desc 'Recreate binaries in a collection'
    task :recreate_in_collection, [:uuid] => :environment do |task, args|
      collection = Collection.find_by_repository_id(args[:uuid])
      ActiveRecord::Base.transaction do
        MedusaIngester.new.recreate_binaries(collection)
      end
    end

    desc 'Populate the byte sizes of all binaries'
    task :populate_byte_sizes => :environment do |task|
      Binary.uncached do
        binaries = Binary.where(byte_size: nil).
            where('repository_relative_pathname IS NOT NULL')
        count = binaries.count
        puts "#{count} binaries to update"

        binaries.find_each.with_index do |binary, index|
          puts "(#{((index / count.to_f) * 100).round(2)}%) "\
              "#{binary.repository_relative_pathname} "

          begin
            binary.read_size
            binary.save!
          rescue => e
            puts e
            CustomLogger.instance.error("#{e}")
          end
        end
      end
    end

    desc 'Populate the dimensions of all binaries'
    task :populate_dimensions => :environment do |task|
      Binary.uncached do
        binaries = Binary.where('(width IS NULL OR height IS NULL)').
            where('media_type LIKE \'image/%\' OR media_type LIKE \'video/%\'').
            where('repository_relative_pathname IS NOT NULL')
        count = binaries.count
        puts "#{count} binaries to update"

        binaries.find_each.with_index do |binary, index|
          puts "(#{((index / count.to_f) * 100).round(2)}%) "\
              "#{binary.repository_relative_pathname} "

          begin
            binary.read_dimensions
            binary.save!
          rescue => e
            puts e
            CustomLogger.instance.error("#{e}")
          end
        end
      end
    end

    desc 'Populate the durations of all binaries'
    task :populate_durations => :environment do |task|
      Binary.uncached do
        binaries = Binary.where(duration: nil).
            where('media_type LIKE \'audio/%\' OR media_type LIKE \'video/%\'').
            where('repository_relative_pathname IS NOT NULL')
        count = binaries.count
        puts "#{count} binaries to update"

        binaries.find_each.with_index do |binary, index|
          puts "(#{((index / count.to_f) * 100).round(2)}%) "\
              "#{binary.repository_relative_pathname} "

          begin
            binary.read_duration
            binary.save!
          rescue => e
            CustomLogger.instance.error("#{e}")
          end
        end
      end
    end

    desc 'Populate the media category of all binaries'
    task :populate_media_categories => :environment do |task|
      Binary.uncached do
        binaries = Binary.where(media_category: nil).
            where('media_type IS NOT NULL')
        count = binaries.count
        puts "#{count} binaries to update"

        binaries.find_each.with_index do |binary, index|
          puts "(#{((index / count.to_f) * 100).round(2)}%) "\
              "#{binary.repository_relative_pathname} "

          binary.media_category =
              Binary::MediaCategory::media_category_for_media_type(binary.media_type)
          binary.save!
        end
      end
    end

  end

  namespace :collections do

    desc 'Publish a collection'
    task :publish, [:uuid] => :environment do |task, args|
      Collection.find_by_repository_id(args[:uuid]).
          update!(public_in_medusa: true, published_in_dls: true)
    end

    desc 'Reindex all collections'
    task :reindex => :environment do |task, args|
      reindex_collections
    end

    desc 'Sync collections from Medusa'
    task :sync => :environment do |task|
      SyncCollectionsJob.new.perform_in_foreground
    end

  end

  namespace :downloads do

    desc 'Clean up old downloads'
    task :cleanup => :environment do |task, args|
      Download.cleanup(60 * 60 * 24) # max 1 day old
    end

    desc 'Expire all downloads'
    task :expire => :environment do |task, args|
      Download.all.each { |dl| dl.expire }
    end

  end

  namespace :elements do

    ##
    # This was requested by mhan3@illinois.edu in June 2017.
    #
    desc 'Generate a report of all names'
    task :mhan3 => :environment do |task, args|
      sql = "SELECT collections.repository_id AS collection_id,
          items.repository_id AS item_id, entity_elements.name,
          entity_elements.value, entity_elements.uri
        FROM entity_elements
        LEFT JOIN items ON entity_elements.item_id = items.id
        LEFT JOIN collections ON collections.repository_id = items.collection_repository_id
        WHERE entity_elements.type = $1
          AND entity_elements.name IN ($2, $3)
          AND collections.public_in_medusa = true
        ORDER BY collection_id, item_id, entity_elements.name,
          entity_elements.value ASC"

      values = [[ nil, 'ItemElement' ], [ nil, 'creator' ], [nil, 'contributor']]

      tsv = "collection_id\titem_id\telement_name\telement_value\telement_uri" +
          ItemTsvExporter::LINE_BREAK
      ActiveRecord::Base.connection.exec_query(sql, 'SQL', values).each do |row|
        tsv += row.values.join("\t") + ItemTsvExporter::LINE_BREAK
      end
      puts tsv
    end

    ##
    # This was requested by lampron2@illinois.edu on 11/2/2017.
    #
    desc 'Generate a report for PL'
    task :plampron2_1 => :environment do |task, args|
      sql = "SELECT collections.repository_id AS collection_id,
          items.repository_id AS item_id, entity_elements.name,
          entity_elements.value, entity_elements.uri
        FROM entity_elements
        LEFT JOIN items ON entity_elements.item_id = items.id
        LEFT JOIN collections ON collections.repository_id = items.collection_repository_id
        WHERE entity_elements.type = $1
          AND entity_elements.name IN ($2, $3)
          AND collections.public_in_medusa = true
        ORDER BY collection_id, item_id, entity_elements.name,
          entity_elements.value ASC"

      values = [[ nil, 'ItemElement' ], [ nil, 'type' ], [nil, 'genre']]

      tsv = "collection_id\titem_id\telement_name\telement_value\telement_uri" +
          ItemTsvExporter::LINE_BREAK
      ActiveRecord::Base.connection.exec_query(sql, 'SQL', values).each do |row|
        tsv += row.values.join("\t") + ItemTsvExporter::LINE_BREAK
      end
      puts tsv
    end

    ##
    # This was requested by lampron2@illinois.edu on 1/18/2018.
    #
    desc 'Generate a report for PL'
    task :elements_in_profiles => :environment do |task, args|
      lines = []
      Element.all.order(:name).each do |el|
        any = false
        MetadataProfile.all.order(:name).each do |mp|
          if mp.elements.where(name: el.name).count > 0
            any = true
            lines << "#{el.name}\t#{mp.name}"
          end
        end
        unless any
          lines << "#{el.name}\t"
        end
      end
      puts lines.join(ItemTsvExporter::LINE_BREAK)
    end

    ##
    # This was requested by lampron2@illinois.edu on 1/18/2018.
    #
    desc 'Generate a report for PL'
    task :plampron2_3 => :environment do |task, args|
      sql = "SELECT collections.repository_id AS collection_id,
          items.repository_id AS item_id, entity_elements.name,
          entity_elements.value, entity_elements.uri
        FROM entity_elements
        LEFT JOIN items ON entity_elements.item_id = items.id
        LEFT JOIN collections ON collections.repository_id = items.collection_repository_id
        WHERE entity_elements.type = $1
          AND entity_elements.name IN ($2, $3, $4)
          AND collections.public_in_medusa = true
        ORDER BY collection_id, item_id, entity_elements.name,
          entity_elements.value ASC"

      values = [[ nil, 'ItemElement' ], [ nil, 'provider' ], [nil, 'owner'], [nil, 'source']]

      tsv = "collection_id\titem_id\telement_name\telement_value\telement_uri" +
          ItemTsvExporter::LINE_BREAK
      ActiveRecord::Base.connection.exec_query(sql, 'SQL', values).each do |row|
        tsv += row.values.join("\t") + ItemTsvExporter::LINE_BREAK
      end
      puts tsv
    end

  end

  namespace :images do

    desc 'Purge all images from the image server cache'
    task :purge_all => :environment do |task, args|
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

  namespace :items do

    desc 'Delete all items from a collection'
    task :purge_collection, [:uuid] => :environment do |task, args|
      Collection.find_by_repository_id(args[:uuid]).purge
    end

    desc 'Reindex an item and all of its children. Omit uuid to index all items'
    task :reindex, [:uuid] => :environment do |task, args|
      if args[:uuid].present?
        item = Item.find_by_repository_id(args[:uuid])
        item.all_children.push(item).each do |it|
          it.reindex
        end
      else
        reindex_items
      end
    end

    desc 'Reindex items in a collection'
    task :reindex_collection, [:uuid] => :environment do |task, args|
      Item.where(collection_repository_id: args[:uuid]).each do |item|
        item.reindex
      end
    end

    desc 'Sync items from Medusa (modes: create_only, recreate_binaries, delete_missing)'
    task :sync, [:collection_uuid, :mode] => :environment do |task, args|
      SyncItemsJob.new(args[:collection_uuid], args[:mode],
                       extract_metadata: false).perform_in_foreground
    end

    desc 'Update items from a TSV file'
    task :update_from_tsv, [:pathname] => :environment do |task, args|
      UpdateItemsFromTsvJob.new(args[:pathname]).perform_in_foreground
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

  def reindex_agents
    Agent.reindex_all
  end

  def reindex_collections
    Collection.reindex_all
  end

  def reindex_items
    Item.reindex_all
  end

end
