namespace :peartree do

  desc 'Clear stale tasks'
  task :clear_stale_tasks => :environment do |task, args|
    Task.where(status: [Task::Status::WAITING, Task::Status::RUNNING]).
        where('updated_at < ?', 1.day.ago).destroy_all
  end

  desc 'Publish a collection'
  task :publish_collection, [:uuid] => :environment do |task, args|
    Collection.find_by_repository_id(args[:uuid]).
        update!(published: true, published_in_dls: true)
  end

  desc 'Delete all items from a collection'
  task :purge_collection, [:uuid] => :environment do |task, args|
    ActiveRecord::Base.transaction do
      Item.where(collection_repository_id: args[:uuid]).destroy_all
    end
    Solr.instance.commit
  end

  desc 'Reindex all database entities'
  task :reindex => :environment do |task, args|
    reindex_all
    Solr.instance.commit
  end

  def reindex_all
    Item.all.each { |item| item.index_in_solr }
    reindex_collections
  end

  desc 'Reindex collection'
  task :reindex_collection, [:uuid] => :environment do |task, args|
    Item.where(collection_repository_id: args[:uuid]).each do |item|
      item.index_in_solr
    end
    Solr.instance.commit
  end

  desc 'Reindex all collections'
  task :reindex_collections => :environment do |task, args|
    reindex_collections
    Solr.instance.commit
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

  desc 'Sync collections from Medusa'
  task :sync_collections => :environment do |task|
    SyncCollectionsJob.new.perform_now
  end

  desc 'Sync items from Medusa (modes: create_only, update_bytestreams, delete_missing)'
  task :sync_items, [:collection_uuid, :mode] => :environment do |task, args|
    SyncItemsJob.new(args[:collection_uuid], args[:mode],
                     extract_metadata: false).perform_now
    Solr.instance.commit
  end

  desc 'Update bytestreams in all collections'
  task :update_bytestreams => :environment do |task|
    ActiveRecord::Base.transaction do
      Collection.all.each do |collection|
        next if collection.items.count == 0
        puts collection.title
        warnings = []
        MedusaIngester.new.ingest_items(collection,
                                        MedusaIngester::IngestMode::UPDATE_BYTESTREAMS,
                                        { extract_metadata: false },
                                        warnings)
        warnings.each { |w| puts w }
      end
    end
    Solr.instance.commit
  end

  desc 'Update the sizes of all bytestreams'
  task :update_byte_sizes => :environment do |task|
    Bytestream.where('repository_relative_pathname IS NOT NULL').each do |bs|
      puts bs.repository_relative_pathname
      pathname = bs.absolute_local_pathname
      bs.byte_size = (pathname and File.exist?(pathname) and File.file?(pathname)) ?
          File.size(pathname) : nil
      bs.save!
    end
  end

  desc 'Update the dimensions of all bytestreams'
  task :update_dimensions => :environment do |task|
    Bytestream.where('repository_relative_pathname IS NOT NULL').each do |bs|
      puts bs.repository_relative_pathname
      bs.read_dimensions
      bs.save!
    end
  end

  desc 'Update items from a TSV file'
  task :update_from_tsv, [:pathname] => :environment do |task, args|
    count = ItemTsvIngester.new.ingest_pathname(args[:pathname])
    Solr.instance.commit
    puts "#{count} items updated."
  end

end
