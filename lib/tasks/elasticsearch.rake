# N.B. Elastic provides some Elasticsearch Rake tasks in the
# elasticsearch-rails gem, but they don't really work how we want them to, so
# they aren't included.

namespace :elasticsearch do

  namespace :indexes do

    desc 'Create a current index for the given model'
    task :create_current, [:model] => :environment do |task, args|
      class_ = args[:model].constantize
      create_current_index(class_)
    end

    desc 'Create all current indexes'
    task :create_all_current => :environment do |task, args|
      EntityFinder::ENTITIES.each do |class_|
        create_current_index(class_)
      end
    end

    desc 'Create all latest indexes'
    task :create_all_latest => :environment do |task, args|
      EntityFinder::ENTITIES.each do |class_|
        create_latest_index(class_)
      end
    end

    desc 'Print the current schema version'
    task :current_version => :environment do
      puts ElasticsearchIndex.current_index_version
    end

    desc 'Delete an index by name'
    task :delete, [:name] => :environment do |task, args|
      ElasticsearchClient.instance.delete_index(args[:name])
    end

    desc 'Delete a current index'
    task :delete_current, [:model] => :environment do |task, args|
      class_ = args[:model].constantize
      delete_current_index(class_)
    end

    desc 'Delete all current indexes'
    task :delete_all_current => :environment do |task, args|
      EntityFinder::ENTITIES.each do |class_|
        delete_current_index(class_)
      end
    end

    desc 'Delete all latest indexes'
    task :delete_all_latest => :environment do |task, args|
      if ElasticsearchIndex.current_index_version !=
          ElasticsearchIndex.latest_index_version
        EntityFinder::ENTITIES.each do |class_|
          delete_latest_index(class_)
        end
      else
        STDERR.puts 'Latest index version is the same as the current version. '\
            'Use delete_all_current if you\'re sure you want to delete them.'

      end
    end

    desc 'List indexes'
    task :list => :environment do |task, args|
      puts ElasticsearchClient.instance.indexes
    end

    desc 'Migrate to the latest schema_version'
    task :migrate_to_latest => :environment do |task, args|
      ElasticsearchIndex.migrate_to_latest
      puts 'Done. Restart required.'
    end

    desc 'Populate/reindex the current indexes with documents'
    task :populate_current => :environment do |task, args|
      EntityFinder::ENTITIES.each do |class_|
        class_.reindex_all(:current)
      end
    end

    desc 'Populate/reindex the latest indexes with documents'
    task :populate_latest => :environment do |task, args|
      EntityFinder::ENTITIES.each do |class_|
        class_.reindex_all(:latest)
      end
      puts 'Done populating latest indexes. Don\'t forget to migrate to them!'
    end

    desc 'Rollback to the previous schema version'
    task :rollback_to_previous => :environment do |task, args|
      ElasticsearchIndex.rollback_to_previous
      puts 'Done. Restart required.'
    end

    desc 'Show schema versions'
    task :schema_versions => :environment do |task, args|
      puts "Current: #{ElasticsearchIndex.current_index_version}"
      puts "Latest: #{ElasticsearchIndex.latest_index_version}"
    end

  end

  desc 'Execute an arbitrary query'
  task :query, [:index, :file] => :environment do |task, args|
    index = args[:index]
    file_path = File.expand_path(args[:file])
    json = File.read(file_path)
    puts ElasticsearchClient.instance.query(index, json)

    curl_cmd = sprintf('curl -X POST -H "Content-Type: application/json" '\
        '"%s/%s/_search?pretty=true&size=0" -d @"%s"',
            Configuration.instance.elasticsearch_endpoint,
            index,
            file_path)
    puts 'cURL equivalent: ' + curl_cmd
  end

  def create_current_index(class_)
    index = ElasticsearchIndex.current_index(class_)
    ElasticsearchClient.instance.create_index(index.name, index.schema)
  end

  def delete_current_index(class_)
    index = ElasticsearchIndex.current_index(class_)
    ElasticsearchClient.instance.delete_index(index.name)
  end

  def create_latest_index(class_)
    index = ElasticsearchIndex.latest_index(class_)
    ElasticsearchClient.instance.create_index(index.name, index.schema)
  end

  def delete_latest_index(class_)
    index = ElasticsearchIndex.latest_index(class_)
    ElasticsearchClient.instance.delete_index(index.name)
  end

end
