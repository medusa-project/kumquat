##
# Singleton class interfacing with Solr.
#
class Solr

  include Singleton

  SCHEMA = YAML.load(File.read(File.join(__dir__, 'schema.yml')))

  @@logger = CustomLogger.instance

  ##
  # Escapes the protected Solr sequences:
  #
  #     + - && || ! ( ) { } [ ] ^ " ~ * ? : \
  #
  # @param query [String]
  # @return [String]
  #
  def self.escape(query)
    query.to_s.
        # strip parentheses
        gsub(/[()]/, '').
        # escape the protected sequences
        gsub(/(\+|-|(&&)|(\|\|)|!|\(|\)|{|}|\[|\]|\^|"|~|\*|\?|:|\\)/, 'NOSPACE \\0').
        gsub('NOSPACE ', '\\')
  end

  ##
  # @param doc [Hash]
  #
  def add(doc)
    @@logger.debug("Solr.add(): #{doc['id']}")
    client.add(doc)
  end

  def commit
    @@logger.debug('Solr.commit()')
    client.commit
  end

  ##
  # @param id [String]
  #
  def delete(id)
    @@logger.debug("Solr.delete(): #{id}")
    client.delete_by_id(id)
  end

  ##
  # @param query [String]
  #
  def delete_by_query(query)
    @@logger.debug("Solr.delete_by_query(): #{query}")
    client.delete_by_query(query)
  end

  alias_method :delete_by_id, :delete

  def get(endpoint, options = {})
    @@logger.debug("Solr.get(): requesting #{endpoint}; #{options}")
    client.get(endpoint, options)
  end

  ##
  # Deletes everything.
  #
  def purge
    @@logger.info('Solr.purge()')
    client.delete_by_query('*:*')
  end

  ##
  # @param term [String] Search term
  # @return [Array] String suggestions
  #
  def suggestions(term)
    suggestions = []
    result = get('suggest', params: { q: term })
    if result['spellcheck']
      struct = result['spellcheck']['suggestions']
      if struct.any?
        suggestions = struct[1]['suggestion']
      end
    end
    suggestions
  end

  ##
  # Creates the set of fields and fieldTypes needed by the application. This
  # requires Solr 5.2+ with the ManagedIndexSchemaFactory enabled and a
  # mutable schema.
  #
  def update_schema
    http = HTTPClient.new
    url = Configuration.instance.solr_url.chomp('/') + '/' +
        Configuration.instance.solr_core

    @@logger.debug('Solr.update_schema(): retrieving current schema')
    response = http.get("#{url}/schema")
    current = JSON.parse(response.body)

    # ************************ FIELD TYPES *************************

    # We are not going to delete existing field types, as there is no downside
    # to leaving them in place.

    # Add new fieldTypes
    field_types_to_add = SCHEMA['fieldTypes'].reject do |kf|
      current['schema']['fieldTypes'].
          map{ |sf| sf['name'] }.include?(kf['name'])
    end
    @@logger.debug('Solr.update_schema(): adding fieldTypes')
    post_fields(http, url, 'add-field-type', field_types_to_add)

    # Replace (update) existing fieldTypes
    @@logger.debug('Solr.update_schema(): updating fieldTypes')
    post_fields(http, url, 'replace-field-type', SCHEMA['fieldTypes'])

    # ************************ DYNAMIC FIELDS *************************

    # Delete obsolete dynamic fields
    dynamic_fields_to_delete = current['schema']['dynamicFields'].select do |cf|
      !SCHEMA['dynamicFields'].map{ |sf| sf['name'] }.include?(cf['name'])
    end
    dynamic_fields_to_delete.each do |df|
      @@logger.debug('Solr.update_schema(): deleting dynamicFields')
      post_fields(http, url, 'delete-dynamic-field', { 'name' => df['name'] })
    end

    # Add new dynamic fields
    dynamic_fields_to_add = SCHEMA['dynamicFields'].reject do |kf|
      current['schema']['dynamicFields'].
          map{ |sf| sf['name'] }.include?(kf['name'])
    end
    @@logger.debug('Solr.update_schema(): adding dynamicFields')
    post_fields(http, url, 'add-dynamic-field', dynamic_fields_to_add)

    # Replace (update) existing dynamic fields
    @@logger.debug('Solr.update_schema(): updating dynamicFields')
    post_fields(http, url, 'replace-dynamic-field', SCHEMA['dynamicFields'])

    # ************************ COPY FIELDS *************************

    # Delete obsolete copyFields
    copy_fields_to_delete = current['schema']['copyFields'].select do |kf|
      !SCHEMA['copyFields'].map{ |sf| "#{sf['source']}#{sf['dest']}" }.
          include?("#{kf['source']}#{kf['dest']}") if SCHEMA['copyFields']
    end
    @@logger.debug('Solr.update_schema(): deleting copyFields')
    post_fields(http, url, 'delete-copy-field', copy_fields_to_delete)

    # Add new copyFields
    if SCHEMA['copyFields']
      copy_fields_to_add = SCHEMA['copyFields'].reject do |kf|
        current['schema']['copyFields'].
            map{ |sf| "#{sf['source']}#{sf['dest']}" }.
            include?("#{kf['source']}#{kf['dest']}")
      end
      @@logger.debug('Solr.update_schema(): adding copyFields')
      post_fields(http, url, 'add-copy-field', copy_fields_to_add)
    end
  end

  private

  def client
    config = Configuration.instance
    @client = RSolr.connect(url: config.solr_url.chomp('/') + '/' +
        config.solr_core) unless @client
    @client
  end

  ##
  # @param http [HTTPClient]
  # @param url [String]
  # @param key [String]
  # @param fields [Array]
  # @raises [RuntimeError]
  #
  def post_fields(http, url, key, fields)
    if fields.any?
      json = JSON.generate({ key => fields })
      response = http.post("#{url}/schema", json,
                           { 'Content-Type' => 'application/json' })
      message = JSON.parse(response.body)
      if message['errors']
        raise "Failed to update Solr schema: #{message['errors']}"
      end
    end
  end

end
