namespace :peartree do

  desc 'Index collections'
  task :index_collections => :environment do |task|
    MedusaIndexer.new.index_collections
    Solr.instance.commit
  end

  desc 'Index all items in a directory tree'
  task :index_path, [:pathname] => :environment do |task, args|
    ItemIngester.new.ingest_pathname(args[:pathname])
    Solr.instance.commit
  end

  desc 'Validate an XML file'
  task :validate, [:pathname] => :environment do |task, args|
    if ItemIngester.new.validate_pathname(args[:pathname])
      puts 'OK'
    end
  end

end
