namespace :peartree do

  desc 'Harvest collections from Medusa'
  task :harvest_collections => :environment do |task|
    MedusaIndexer.new.index_collections
    Solr.instance.commit
  end

  desc 'Ingest all items in a directory tree'
  task :ingest_path, [:pathname, :schema_version] => :environment do |task, args|
    ItemXmlIngester.new.ingest_pathname(args[:pathname],
                                        args[:schema_version].to_i)
    Solr.instance.commit
  end

  desc 'Publish a collection'
  task :publish_collection, [:id] => :environment do |task, args|
    Collection.find_by_repository_id(args[:id]).
        update!(published: true, published_in_dls: true)
  end

  desc 'Reindex all entities'
  task :reindex => :environment do |task, args|
    reindex_all
    Solr.instance.commit
  end

  def reindex_all
    Item.all.each { |item| item.index_in_solr }
    reindex_collections
  end

  desc 'Reindex all collections'
  task :reindex_collections => :environment do |task, args|
    reindex_collections
    Solr.instance.commit
  end

  def reindex_collections
    # Reindex existing collections
    Collection.all.each { |col| col.index_in_solr }
    # Remove indexed documents whose entities have disappeared
    Collection.solr.all.select{ |c| c.to_s == c }.each do |col_id|
      Solr.delete_by_id(col_id)
    end
  end

  desc 'Validate an XML file'
  task :validate, [:pathname, :schema_version] => :environment do |task, args|
    if ItemXmlIngester.new.validate_pathname(args[:pathname],
                                             args[:schema_version].to_i)
      puts 'OK'
    end
  end

end
