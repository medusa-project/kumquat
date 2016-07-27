namespace :peartree do

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
    MedusaIngester.new.ingest_collections
    Solr.instance.commit
  end

  desc 'Sync items from Medusa (modes: create_only, update_bytestreams, delete_missing)'
  task :sync_items, [:collection_uuid, :mode] => :environment do |task, args|
    collection = Collection.find_by_repository_id(args[:collection_uuid])
    warnings = []
    result = MedusaIngester.new.ingest_items(collection, args[:mode], warnings)
    Solr.instance.commit
    warnings.each { |w| puts w }
    puts "#{args[:mode]} sync of #{collection.title}:\n"\
        "    Created: #{result[:num_created]}\n"\
        "    Updated: #{result[:num_updated]}\n"\
        "    Deleted: #{result[:num_deleted]}\n"\
        "    Skipped: #{result[:num_skipped]}\n"
  end

  desc 'Update items from a TSV file'
  task :update_from_tsv, [:pathname] => :environment do |task, args|
    count = ItemTsvIngester.new.ingest_pathname(args[:pathname])
    Solr.instance.commit
    puts "#{count} items updated."
  end

end
