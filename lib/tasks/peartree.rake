namespace :peartree do

  desc 'Index a pathname'
  task :index, [:pathname] => :environment do |task, args|
    ReindexJob.perform_later(pathname: File.expand_path(args[:pathname]))
  end

  desc 'Validate an XML file'
  task :validate, [:pathname] => :environment do |task, args|
    if Indexer.new.validate(File.expand_path(args[:pathname]))
      puts 'OK'
    end
  end

end
