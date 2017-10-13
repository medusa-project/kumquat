##
# Custom Elasticsearch client.
#
# N.B.: This client is completely different from `Elasticsearch::Client`
# provided by the `elasticsearch-model` gem.
#
class ElasticsearchClient

  include Singleton

  MAX_RESULT_WINDOW = 10000

  @@http_client = HTTPClient.new
  @@logger = CustomLogger.instance

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
  # @param index [Symbol] :current or :latest
  # @param class_ [Class] Model class.
  # @param id [String] Document ID.
  # @param doc [Hash] Hash that can be encoded as JSON.
  # @return [void]
  #
  def index_document(index, class_, id, doc)
    case index
      when :latest
        index_name = ElasticsearchIndex.latest_index(class_).name
      else
        index_name = ElasticsearchIndex.current_index(class_).name
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
  # @return [String] Summary of all indexes in the node.
  #
  def indexes
    response = @@http_client.get(Configuration.instance.elasticsearch_endpoint +
                                     '/_aliases?pretty')
    response.body
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
  # @param class_ [Elasticsearch::Model] Elasticsearch model class.
  # @return [void]
  #
  def recreate_index(class_)
    index = ElasticsearchIndex.current_index(class_)
    delete_index(index.name)
    create_index(index.name, index.schema)
  end

end