namespace :peartree do

  desc 'Harvest collections from Medusa'
  task :harvest_collections => :environment do |task|
    MedusaIndexer.new.index_collections
    Solr.instance.commit
  end

  desc 'Ingest items in a TSV file'
  task :ingest_tsv, [:pathname, :collection_uuid] => :environment do |task, args|
    collection = Collection.find_by_repository_id(args[:collection_uuid])
    ItemTsvIngester.new.ingest_pathname(args[:pathname], collection)
    Solr.instance.commit
  end

  # TODO: This is temporary and should be removed once this has been done in
  # all environments.
  desc 'Migrate representative images to UUIDs'
  task :migrate_representative_images => :environment do |task|
    client = Medusa.client
    response = client.get('https://medusa.library.illinois.edu/collections.json')
    collections = JSON.parse(response.body)
    collections.each do |c|
      col_resp = client.get('https://medusa.library.illinois.edu/collections/' +
                                c['id'].to_s + '.json')
      col = JSON.parse(col_resp.body)

      if col['representative_image'].length > 0
        rep_image = col['representative_image']

        file_resp = client.get('https://medusa.library.illinois.edu/cfs_files/' +
                                   rep_image + '.json')
        file = JSON.parse(file_resp.body)
        if file['uuid']
          rep_image = file['uuid']
        end

        col = Collection.find_by_repository_id(col['uuid'])
        col.representative_image = rep_image
        col.save!
      end
    end


    #Solr.instance.commit
  end

  desc 'Publish a collection'
  task :publish_collection, [:uuid] => :environment do |task, args|
    Collection.find_by_repository_id(args[:uuid]).
        update!(published: true, published_in_dls: true)
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
