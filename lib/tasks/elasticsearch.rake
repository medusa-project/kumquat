# N.B. Elastic provides some Elasticsearch Rake tasks in the
# elasticsearch-rails gem, but they don't really work how we want them to, so
# they aren't included.

namespace :elasticsearch do

  desc 'Create a current index for the given model'
  task :create_current_index, [:model] => :environment do |task, args|
    class_ = args[:model].constantize
    create_current_index(class_)
  end

  desc 'Create all current indexes'
  task :create_current_indexes => :environment do |task, args|
    EntityFinder::ENTITIES.each do |class_|
      create_current_index(class_)
    end
  end

  desc 'Get the current index name for the given model'
  task :current_index_name, [:model] => :environment do |task, args|
    class_ = args[:model].constantize
    puts ElasticsearchClient.current_index_name(class_)
  end

  desc 'Create all next indexes'
  task :create_next_indexes => :environment do |task, args|
    EntityFinder::ENTITIES.each do |class_|
      create_next_index(class_)
    end
  end

  desc 'Delete a current index'
  task :delete_current_index, [:model] => :environment do |task, args|
    class_ = args[:model].constantize
    delete_current_index(class_)
  end

  desc 'Delete all current indexes'
  task :delete_current_indexes => :environment do |task, args|
    EntityFinder::ENTITIES.each do |class_|
      delete_current_index(class_)
    end
  end

  desc 'Delete an index by name'
  task :delete_index, [:name] => :environment do |task, args|
    ElasticsearchClient.instance.delete_index(args[:name])
  end

  desc 'List indexes'
  task :list_indexes => :environment do |task, args|
    puts ElasticsearchClient.instance.indexes
  end

  desc 'Migrate schema_versions'
  task :migrate_schema_versions => :environment do |task, args|
    ElasticsearchClient.instance.migrate_schemas
    puts 'Done. Restart required.'
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

  desc 'Populate the current indexes with documents'
  task :reindex_current_indexes => :environment do |task, args|
    EntityFinder::ENTITIES.each do |class_|
      class_.reindex_all(:current)
    end
  end

  desc 'Populate the next indexes with documents'
  task :reindex_next_indexes => :environment do |task, args|
    EntityFinder::ENTITIES.each do |class_|
      class_.reindex_all(:next)
    end
  end

  desc 'Rollback schema_versions'
  task :rollback_schema_versions => :environment do |task, args|
    ElasticsearchClient.instance.rollback_schemas
    puts 'Done. Restart required.'
  end

  desc 'Show schema versions'
  task :schema_versions => :environment do |task, args|
    puts "Current: #{ElasticsearchClient.current_index_version}"
    puts "Next: #{ElasticsearchClient.next_index_version}"
  end

  def create_current_index(class_)
    index_name = ElasticsearchClient.current_index_name(class_)
    schema = class_::CURRENT_INDEX_SCHEMA
    ElasticsearchClient.instance.create_index(index_name, schema)
  end

  def delete_current_index(class_)
    index_name = ElasticsearchClient.current_index_name(class_)
    ElasticsearchClient.instance.delete_index(index_name)
  end

  def create_next_index(class_)
    index_name = ElasticsearchClient.next_index_name(class_)
    schema = class_::NEXT_INDEX_SCHEMA
    ElasticsearchClient.instance.create_index(index_name, schema)
  end

  def delete_next_index(class_)
    index_name = ElasticsearchClient.next_index_name(class_)
    ElasticsearchClient.instance.delete_index(index_name)
  end

end
