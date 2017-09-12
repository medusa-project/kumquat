##
# Custom Elasticsearch client.
#
# N.B.: This client is completely different from `Elasticsearch::Client`
# provided by the `elasticsearch-model` gem.
#
# # Index schemas
#
# Elasticsearch indexes can't be changed in place (and that might not be good
# practice anyway), so new ones have to be created with the desired changes.
# Accordingly, the application incorporates concepts of "current" and "next"
# index schemas. All indexed models need to define an
# `CURRENT_INDEX_SCHEMA` constant that defines their current
# schema. When the schema changes, the new schema must be defined as
# `NEXT_INDEX_SCHEMA`. Then, the next indexes must be created and
# populated with documents. (Typically this is done with rake tasks; see
# below.)
#
# # Index migration
#
# 1. Define `NEXT_INDEX_SCHEMA` on all models
# 2. `bin/rails elasticsearch:create_next_indexes`
# 3. `bin/rails elasticsearch:populate_next_indexes`
# 4. `bin/rails elasticsearch:migrate_schema_versions`
# 5. Rename `NEXT_INDEX_SCHEMA` to
#    `CURRENT_INDEX_SCHEMA` on all models
# 6. Restart
#
class ElasticsearchClient

  include Singleton

  APPLICATION_INDEX_PREFIX = 'dls'
  MAX_RESULT_WINDOW = 10000

  @@http_client = HTTPClient.new
  @@logger = CustomLogger.instance

  ##
  # @param class_ [Class] Model class.
  # @return [String] Name of the current index to use for the given model class.
  #
  def self.current_index_name(class_)
    sprintf('%s_%s_%s_%s',
            APPLICATION_INDEX_PREFIX,
            current_index_version,
            class_.to_s.downcase.pluralize,
            Rails.env)
  end

  ##
  # @return [Integer]
  #
  def self.current_index_version
    Option::integer(Option::Keys::CURRENT_INDEX_VERSION) || 0
  end

  ##
  # @param class_ [Class] Model class.
  # @return [String] Name of the next index to use for the given model class.
  #
  def self.next_index_name(class_)
    sprintf('%s_%s_%s_%s',
            APPLICATION_INDEX_PREFIX,
            next_index_version,
            class_.to_s.downcase.pluralize,
            Rails.env)
  end

  ##
  # @return [Integer]
  #
  def self.next_index_version
    Option::integer(Option::Keys::NEXT_INDEX_VERSION) || 1
  end

  ##
  # @param name [String] Index name.
  # @param schema [Hash] Schema structure that can be encoded as JSON.
  # @return [Boolean]
  #
  def create_index(name, schema)
    @@logger.info("ElasticsearchClient.create_index(): creating #{name}...")
    response = @@http_client.put(Configuration.instance.elasticsearch_endpoint +
                                     '/' + name, JSON.generate(schema))
    if response.status == 200
      @@logger.info("ElasticsearchClient.create_index(): created #{name}")
    else
      @@logger.info("ElasticsearchClient.create_index(): "\
          "got #{response.status} for #{name}:\n#{JSON.pretty_generate(JSON.parse(response.body))}")
    end
  end

  ##
  # @param name [String] Index name.
  # @return [Boolean]
  #
  def delete_index(name)
    @@logger.info("ElasticsearchClient.delete_index(): deleting #{name}...")
    response = @@http_client.delete(Configuration.instance.elasticsearch_endpoint +
                                        '/' + name)
    if response.status == 200
      @@logger.info("ElasticsearchClient.delete_index(): #{name} deleted")
    else
      @@logger.info("ElasticsearchClient.delete_index(): "\
          "got #{response.status} for #{name}")
    end
  end

  ##
  # @param index [Symbol] :current or :next
  # @param class_ [Class] Model class.
  # @param id [String] Document ID.
  # @param doc [Hash] Hash that can be encoded as JSON.
  # @return [void]
  #
  def index_document(index, class_, id, doc)
    case index
      when :next
        index_name = self.class.next_index_name(class_)
      else
        index_name = self.class.current_index_name(class_)
    end
    url = sprintf('%s/%s/%s/%s',
                  Configuration.instance.elasticsearch_endpoint,
                  index_name,
                  class_.to_s.downcase,
                  id)
    CustomLogger.instance.debug("ElasticsearchClient.index_document(): "\
        "#{index_name}/#{id}")
    response = @@http_client.put(url, JSON.generate(doc))
    if response.status >= 400
      @@logger.error("ElasticsearchClient.index_document(): #{response.body}")
    end
  end

  ##
  # @param name [String] Index name.
  # @return [Boolean]
  #
  def index_exists?(name)
    response = @@http_client.get(Configuration.instance.elasticsearch_endpoint +
                                     '/' + name)
    response.status == 200
  end

  ##
  # @return [Boolean] All indexes in the node.
  #
  def indexes
    response = @@http_client.get(Configuration.instance.elasticsearch_endpoint +
                                     '/_aliases?pretty')
    response.body
  end

  ##
  # @return [void]
  #
  def migrate_schemas
    current_version = self.class.current_index_version || 0
    next_version = self.class.next_index_version || 1
    target_current_version = next_version
    target_next_version = next_version + 1

    @@logger.info("migrate_schemas(): current key: #{current_version}; "\
        "next key: #{next_version}")

    Option.set(Option::Keys::CURRENT_INDEX_VERSION, target_current_version)
    Option.set(Option::Keys::NEXT_INDEX_VERSION, target_next_version)

    @@logger.info("migrate_schemas(): new current key: "\
        "#{target_current_version}; new next key: #{target_next_version}")
  end

  ##
  # @param index [String]
  # @param query [String] JSON query string.
  # @return [String] Response body.
  #
  def query(index, query)
    url = sprintf('%s/%s/_search?size=0&pretty=true',
                  Configuration.instance.elasticsearch_endpoint,
                  index)
    @@http_client.post(url, query).body
  end

  ##
  # @return [void]
  #
  def recreate_all_indexes
    EntityFinder::ENTITIES.each do |class_|
      recreate_index(class_)
    end
  end

  ##
  # @param class_ [Class] One of the Elasticsearch model classes.
  # @return [void]
  #
  def recreate_index(class_)
    index_name = ElasticsearchClient.current_index_name(class_)
    delete_index(index_name)
    create_index(index_name, class_::CURRENT_INDEX_SCHEMA)
  end

  def rollback_schemas
    current_version = self.class.current_index_version || 1
    next_version = self.class.next_index_version || 2
    target_current_version = current_version - 1
    target_next_version = current_version

    @@logger.info("rollback_schemas(): current key: #{current_version}; "\
        "next key: #{next_version}")

    Option.set(Option::Keys::CURRENT_INDEX_VERSION, target_current_version)
    Option.set(Option::Keys::NEXT_INDEX_VERSION, target_next_version)

    @@logger.info("rollback_schemas(): new current key: "\
        "#{target_current_version}; new next key: #{target_next_version}")
  end

end