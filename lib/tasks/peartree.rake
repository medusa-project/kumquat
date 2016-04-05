namespace :peartree do

  desc 'Index collections'
  task :index_collections => :environment do |task|
    MedusaIndexer.new.index_collections
    Solr.instance.commit
  end

  desc 'Index all items in a collection'
  task :index, [:collection_id] => :environment do |task, args|
    col = MedusaCollection.find(args[:collection_id])
    FilesystemIndexer.new.index(col)
    Solr.instance.commit
  end

  desc 'Validate an XML file'
  task :validate, [:pathname] => :environment do |task, args|
    if FilesystemIndexer.new.validate(File.expand_path(args[:pathname]))
      puts 'OK'
    end
  end

end
