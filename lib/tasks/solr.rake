namespace :solr do

  desc 'Commit'
  task :commit => :environment do
    Solr.instance.commit
  end

  desc 'Delete a document'
  task :delete, [:id] => :environment do |task, args|
    solr = Solr.instance
    solr.delete_by_id(args[:id])
    solr.commit
  end

  desc 'Delete everything'
  task :purge => :environment do |task, args|
    solr = Solr.instance
    solr.purge
    solr.commit
  end

  desc 'Update the schema'
  task :update_schema => :environment do
    Solr.instance.update_schema
  end

end
