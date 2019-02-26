##
# Custom Elasticsearch client.
#
class ElasticsearchClient

  include Singleton

  # Field values should be truncated to this length.
  # (32766 total / 3 bytes per character)
  MAX_KEYWORD_FIELD_LENGTH = 10922

  # Default is 10,000. This should remain in sync with the same value in the
  # schema YAML.
  MAX_RESULT_WINDOW = 1000000000

  @@http_client = HTTPClient.new
  @@logger = CustomLogger.instance

  ##
  # @param name [String] Index name.
  # @param schema [Hash] Schema structure that can be encoded as JSON.
  # @return [Boolean]
  # @raises [IOError]
  #
  def create_index(name, schema)
    @@logger.info("ElasticsearchClient.create_index(): creating #{name}...")
    index_url = sprintf('%s/%s',
                        Configuration.instance.elasticsearch_endpoint, name)
    response = @@http_client.put(index_url,
                                 JSON.generate(schema),
                                 'Content-Type': 'application/json')
    if response.status == 200
      @@logger.info("ElasticsearchClient.create_index(): created #{name}")
    else
      raise IOError, "Got #{response.status} for #{name}:\n"\
          "#{JSON.pretty_generate(JSON.parse(response.body))}"
    end

    # Increase the max result window (default is 10,000).
    response = @@http_client.put(index_url,
                                 '{ "index" : { "max_result_window" : 1000000 } }',
                                 'Content-Type': 'application/json')
    if response.status == 200
      @@logger.info("ElasticsearchClient.create_index(): "\
          "updated max result window for #{name}")
    else
      raise IOError, "Got #{response.status}:\n"\
          "#{JSON.pretty_generate(JSON.parse(response.body))}"
    end
  end

  ##
  # @param index_name [String]
  # @param type [String]
  # @return [void]
  # @raises [IOError]
  #
  def delete_all_documents(index_name, type)
    @@logger.info("ElasticsearchClient.delete_all_documents(): deleting all "\
        "documents in index #{index_name}/#{type}...")

    body = {
        query: {
            match_all: {}
        }
    }

    url = sprintf('%s/%s/%s/_delete_by_query?conflicts=proceed',
                  Configuration.instance.elasticsearch_endpoint,
                  index_name, type)
    response = @@http_client.post(url,
                                  JSON.generate(body),
                                  'Content-Type': 'application/json')

    if response.status == 200
      @@logger.info("ElasticsearchClient.delete_all_documents(): all "\
          "documents deleted from #{index_name}")
    else
      raise IOError, "Got #{response.status} for POST #{url}\n#{response.body}"
    end
  end

  ##
  # @param index [String]
  # @param query [String] JSON query string.
  # @return [String] Response body.
  #
  def delete_by_query(index, query)
    url = sprintf('%s/%s/_delete_by_query?pretty',
                  Configuration.instance.elasticsearch_endpoint, index)
    @@logger.debug("ElasticsearchClient.delete_by_query(): #{url}\n    #{query}")
    response = @@http_client.post(url, query,
                                  'Content-Type': 'application/json')
    if response.status != 200
      raise IOError, "Got #{response.status}:\n"\
          "#{JSON.pretty_generate(JSON.parse(response.body))}"
    end
  end

  ##
  # @param name [String] Index name.
  # @return [Boolean]
  # @raises [IOError]
  #
  def delete_index(name)
    @@logger.info("ElasticsearchClient.delete_index(): deleting #{name}...")
    response = @@http_client.delete(Configuration.instance.elasticsearch_endpoint +
                                        '/' + name)
    if response.status == 200
      @@logger.info("ElasticsearchClient.delete_index(): #{name} deleted")
    else
      raise IOError, "Got #{response.status} for #{name}"
    end
  end

  ##
  # @param index [Symbol] :current or :latest
  # @param class_ [Class] Model class.
  # @param id [String] Document ID.
  # @param doc [Hash] Hash that can be encoded as JSON.
  # @return [void]
  # @raises [IOError]
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
    response = @@http_client.put(url,
                                 JSON.generate(doc),
                                 'Content-Type': 'application/json')
    if response.status >= 400
      raise IOError, response.body
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
    url = sprintf('%s/%s/_search',
                  Configuration.instance.elasticsearch_endpoint,
                  index)
    headers = { 'Content-Type': 'application/json' }

    response = @@http_client.post(url, query, headers)

    CustomLogger.instance.debug(
        "ElasticsearchClient.query(): URL: #{url}\n"\
        "  Request: #{query}\n"\
        "  Response: #{response.body}")
    response.body
  end

  ##
  # @return [void]
  # @raises [IOError]
  #
  def recreate_all_indexes
    EntityFinder::ENTITIES.each do |class_|
      recreate_index(class_)
    end
  end

  ##
  # @param class_ [Class] Model class.
  # @return [void]
  # @raises [IOError]
  #
  def recreate_index(class_)
    index = ElasticsearchIndex.current_index(class_)
    begin
      delete_index(index.name)
    rescue IOError => e
      raise e unless e.message.include?('Got 404')
    end
    create_index(index.name, index.schema)
  end

end