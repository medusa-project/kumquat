namespace :solr do

  desc 'Delete a document'
  task :delete, [:id] => :environment do |task, args|
    Solr.client.delete_by_id(args[:id])
    Solr.client.commit
  end

  desc 'Delete everything'
  task :flush => :environment do |task, args|
    Solr.flush
    Solr.client.commit
  end

  desc 'Update the schema'
  task :update_schema => :environment do
    Solr.update_schema
  end

end
