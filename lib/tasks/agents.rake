namespace :agents do

  desc 'Delete orphaned indexed agent documents'
  task :delete_orphaned_documents => :environment do |task, args|
    Agent.delete_orphaned_documents
  end

  desc 'Reindex all agents'
  task :reindex, [:index_name] => :environment do |task, args|
    Agent.reindex_all(es_index: args[:index_name])
  end

end
