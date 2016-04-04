namespace :peartree do

  desc 'Index a pathname'
  task :index, [:pathname] => :environment do |task, args|
    FilesystemIndexer.new.index(args[:pathname])
    Solr.instance.commit
  end

  desc 'Validate an XML file'
  task :validate, [:pathname] => :environment do |task, args|
    if FilesystemIndexer.new.validate(File.expand_path(args[:pathname]))
      puts 'OK'
    end
  end

end
