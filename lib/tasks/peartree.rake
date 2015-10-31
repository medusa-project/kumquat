namespace :peartree do

  desc 'Index a filesystem path'
  task :index, [:pathname] => :environment do |task, args|
    indexer = Indexer.new
    indexer.index_all(File.expand_path(args[:pathname]))
    Solr.client.commit
  end

end
