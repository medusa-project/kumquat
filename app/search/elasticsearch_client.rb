##
# High-level Elasticsearch client.
#
class ElasticsearchClient

  include Singleton

  LOGGER = CustomLogger.new(ElasticsearchClient)

  CONTENT_TYPE = 'application/json'

  # Field values should be truncated to this length.
  # (32766 total / 3 bytes per character)
  MAX_KEYWORD_FIELD_LENGTH = 10922

  # Default is 10,000. This should remain in sync with the same value in the
  # schema YAML.
  MAX_RESULT_WINDOW = 1000000000

  def initialize
    @http_client = HTTPClient.new
  end

  ##
  # @param index_name [String]
  # @return [Boolean]
  # @raises [IOError]
  #
  def create_index(index_name)
    LOGGER.info('create_index(): creating %s...', index_name)
    url = sprintf('%s/%s',
                  Configuration.instance.elasticsearch_endpoint,
                  index_name)
    body = JSON.pretty_generate(ElasticsearchIndex::SCHEMA)
    response = @http_client.put(url, body, 'Content-Type': CONTENT_TYPE)
    if response.status == 200
      LOGGER.info('create_index(): created %s', index_name)
    else
      raise IOError, "Got HTTP #{response.status} for PUT #{url}:\n"\
          "Request: #{body}\n"\
          "Response: #{JSON.pretty_generate(JSON.parse(response.body))}"
    end
  end

  ##
  # @param alias_name [String]
  # @param index_name [String]
  # @return [void]
  #
  def create_index_alias(index_name, alias_name)
    url = sprintf('%s/_aliases', Configuration.instance.elasticsearch_endpoint)
    body = JSON.generate({
        actions: [
            {
                add: {
                    index: index_name,
                    alias: alias_name
                }
            }
        ]
    })
    response = @http_client.post(url, body,
                                 'Content-Type': CONTENT_TYPE)
    if response.status == 200
      LOGGER.info('create_index_alias(): %s -> %s', alias_name, index_name)
    else
      raise IOError, "Got HTTP #{response.status}:\n"\
          "#{JSON.pretty_generate(JSON.parse(response.body))}"
    end
  end

  ##
  # @param query [String] JSON query string.
  # @return [void]
  #
  def delete_by_query(query)
    config = Configuration.instance
    url = sprintf('%s/%s/_delete_by_query?pretty&conflicts=proceed&refresh',
                  config.elasticsearch_endpoint,
                  config.elasticsearch_index)
    LOGGER.debug('delete_by_query(): %s', query)

    response = @http_client.post(url, query,
                                 'Content-Type': CONTENT_TYPE)
    if response.status == 200
      LOGGER.debug('delete_by_query(): %s', response.body)
    else
      raise IOError, "Got HTTP #{response.status} for POST #{url}\n#{response.body}"
    end
  end

  ##
  # @param index_name [String] Index name.
  # @param raise_on_not_found [Boolean]
  # @return [Boolean]
  # @raises [IOError]
  #
  def delete_index(index_name, raise_on_not_found = true)
    LOGGER.info('delete_index(): deleting %s...', index_name)
    url = sprintf('%s/%s',
                  Configuration.instance.elasticsearch_endpoint,
                  index_name)
    response = @http_client.delete(url, nil,
                                   'Content-Type': CONTENT_TYPE)
    if response.status == 200
      LOGGER.info('delete_index(): deleted %s', index_name)
    elsif response.status != 404 or (response.status == 404 and raise_on_not_found)
      raise IOError, "Got HTTP #{response.status} for #{index_name}"
    end
  end

  ##
  # @param index_name [String]
  # @param alias_name [String]
  # @return [void]
  #
  def delete_index_alias(index_name, alias_name)
    LOGGER.info('delete_index_alias(): deleting %s...', alias_name)
    url = sprintf('%s/%s/_alias/%s',
                  Configuration.instance.elasticsearch_endpoint,
                  index_name,
                  alias_name)
    response = @http_client.delete(url, nil,
                                   'Content-Type': CONTENT_TYPE)
    if response.status == 200
      LOGGER.info('delete_index_alias(): deleted %s', alias_name)
    else
      raise IOError, "Got #{response.status} for DELETE #{url}\n"\
          "#{JSON.pretty_generate(JSON.parse(response.body))}"
    end
  end

  ##
  # @param index_name [String]
  # @param id [String]
  # @return [Hash, nil]
  #
  def get_document(index_name, id)
    LOGGER.debug('get_document(): %s/%s', index_name, id)
    url = sprintf('%s/%s/entity/%s',
                  Configuration.instance.elasticsearch_endpoint,
                  index_name, id)
    response = @http_client.get(url, nil, 'Content-Type': CONTENT_TYPE)
    case response.status
    when 200
      JSON.parse(response.body)
    when 404
      nil
    else
      raise IOError, response.body
    end
  end

  ##
  # @param index [String] Index name.
  # @param id [String]    Document ID.
  # @param doc [Hash]     Hash to serialize as JSON.
  # @return [void]
  # @raises [IOError]     If Elasticsearch returns an error response.
  #
  def index_document(index, id, doc)
    LOGGER.debug('index_document(): %s/%s', index, id)
    url = sprintf('%s/%s/entity/%s', # in ES 7, `entity` changes to `_doc`
                  Configuration.instance.elasticsearch_endpoint,
                  index, id)
    response = @http_client.put(url,
                                JSON.generate(doc),
                                'Content-Type': CONTENT_TYPE)
    if response.status >= 400
      raise IOError, response.body
    end
  end

  ##
  # @param name [String] Index or index alias name.
  # @return [Boolean]
  #
  def index_exists?(name)
    url = sprintf('%s/%s',
                  Configuration.instance.elasticsearch_endpoint,
                  name)
    response = @http_client.head(url, nil, 'Content-Type': CONTENT_TYPE)
    response.status == 200
  end

  ##
  # @return [String] Summary of all indexes in the node, as reported by
  #                  Elasticsearch.
  #
  def indexes
    url = sprintf('%s/_aliases?pretty',
                  Configuration.instance.elasticsearch_endpoint)
    response = @http_client.get(url, nil, 'Content-Type': CONTENT_TYPE)
    response.body
  end

  ##
  # @param query [String] JSON query string.
  # @return [String] Response body.
  #
  def query(query)
    config = Configuration.instance
    url = sprintf('%s/%s/_search',
                  config.elasticsearch_endpoint,
                  config.elasticsearch_index)
    body = query.force_encoding('UTF-8')
    response = @http_client.post(url, body, 'Content-Type': CONTENT_TYPE)

    LOGGER.debug("query(): %s\n    Request: %s\n    Response: %s",
                 url, body,
                 response.body.force_encoding('UTF-8'))
    response.body
  end

  ##
  # @param from_index [String]
  # @param to_index [String]
  #
  def reindex(from_index, to_index)
    url = sprintf('%s/_refresh',
                  Configuration.instance.elasticsearch_endpoint)
    body = JSON.generate({
        source: {
            index: from_index
        },
        dest: {
            index: to_index
        }
    })
    response = @http_client.post(url, nil, 'Content-Type': CONTENT_TYPE)

    LOGGER.debug("reindex():\n    Request: %s\n    Response: %s",
                 body.force_encoding('UTF-8'),
                 response.body.force_encoding('UTF-8'))
    response.body
  end

  ##
  # Refreshes an index.
  #
  # @param index [String]
  # @return [void]
  #
  def refresh(index)
    url = sprintf('%s/%s/_refresh',
                  Configuration.instance.elasticsearch_endpoint,
                  index)
    response = @http_client.post(url, nil, 'Content-Type': CONTENT_TYPE)

    LOGGER.debug("refresh(): URL: %s\n"\
                 "  Response: %s",
                 url, response.body)
  end

end