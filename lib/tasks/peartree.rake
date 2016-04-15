namespace :peartree do

  desc 'Index collections'
  task :index_collections => :environment do |task|
    MedusaIndexer.new.index_collections
    Solr.instance.commit
  end

  desc 'Index all items in a directory tree'
  task :index_path, [:pathname, :schema_version] => :environment do |task, args|
    ItemIngester.new.ingest_pathname(args[:pathname],
                                     args[:schema_version].to_i)
    Solr.instance.commit
  end

  desc 'Validate an XML file'
  task :validate, [:pathname, :schema_version] => :environment do |task, args|
    if ItemIngester.new.validate_pathname(args[:pathname],
                                          args[:schema_version].to_i)
      puts 'OK'
    end
  end

end
