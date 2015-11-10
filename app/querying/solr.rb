##
# Singleton class interfacing with Solr.
#
class Solr

  ##
  # All Solr fields used by the application.
  #
  class Fields
    ACCESS_MASTER_HEIGHT = 'access_master_height_ii'
    ACCESS_MASTER_MEDIA_TYPE = 'access_master_media_type_si'
    ACCESS_MASTER_PATHNAME = 'access_master_pathname_si'
    ACCESS_MASTER_URL = 'access_master_url_si'
    ACCESS_MASTER_WIDTH = 'access_master_width_ii'
    CLASS = 'class_si'
    COLLECTION = 'collection_si'
    DATE = 'date_dti'
    FULL_TEXT = 'full_text_txti'
    HEIGHT = 'height_ii'
    ID = 'id'
    LAST_INDEXED = 'last_indexed_dti'
    PARENT_ITEM = 'parent_si'
    PRESERVATION_MASTER_HEIGHT = 'preservation_master_height_ii'
    PRESERVATION_MASTER_MEDIA_TYPE = 'preservation_master_media_type_si'
    PRESERVATION_MASTER_PATHNAME = 'preservation_master_pathname_si'
    PRESERVATION_MASTER_URL = 'preservation_master_url_si'
    PRESERVATION_MASTER_WIDTH = 'preservation_master_width_ii'
    PUBLISHED = 'published_bi'
    SEARCH_ALL = 'searchall_txti'
    TITLE = 'title_txti'
    WEB_ID = 'web_id_si'
  end

  include Singleton

  SCHEMA = YAML.load(File.read(File.join(__dir__, 'schema.yml')))

  ##
  # @param doc [Hash]
  #
  def add(doc)
    Rails.logger.info("Adding Solr document: #{doc['id']}")
    client.add(doc)
  end

  ##
  # @param id [String]
  #
  def delete_by_id(id)
    Rails.logger.info("Deleting Solr document: #{id}")
    client.delete_by_id(id)
  end

  ##
  # Deletes everything.
  #
  def flush
    Rails.logger.info('Flushing Solr')
    client.update(data: '<delete><query>*:*</query></delete>')
  end

  def get(endpoint, options = {})
    Rails.logger.debug("Solr request: #{endpoint}; #{options}")
    client.get(endpoint, options)
  end

  ##
  # @param term [String] Search term
  # @return [Array] String suggestions
  #
  def suggestions(term)
    result = get('suggest', params: { q: term })
    suggestions = result['spellcheck']['suggestions']
    suggestions.any? ? suggestions[1]['suggestion'] : []
  end

  ##
  # Creates the set of fields needed by the application. This requires
  # Solr 5.2+ with the ManagedIndexSchemaFactory enabled and a mutable schema.
  #
  def update_schema
    http = HTTPClient.new
    url = PearTree::Application.peartree_config[:solr_url].chomp('/') + '/' +
        PearTree::Application.peartree_config[:solr_core]

    response = http.get("#{url}/schema")
    current = JSON.parse(response.body)

    # delete obsolete dynamic fields
    dynamic_fields_to_delete = current['schema']['dynamicFields'].select do |cf|
      !SCHEMA['dynamicFields'].map{ |sf| sf['name'] }.include?(cf['name'])
    end
    dynamic_fields_to_delete.each do |df|
      post_fields(http, url, 'delete-dynamic-field', { 'name' => df['name'] })
    end

    # add new dynamic fields
    dynamic_fields_to_add = SCHEMA['dynamicFields'].reject do |kf|
      current['schema']['dynamicFields'].
          map{ |sf| sf['name'] }.include?(kf['name'])
    end
    post_fields(http, url, 'add-dynamic-field', dynamic_fields_to_add)
=begin
    # copy faceted triples into facet fields
    facetable_fields = Triple.where('facet_id IS NOT NULL').
        uniq(&:predicate).map do |t|
      { source: self.class.field_name_for_predicate(t.predicate),
        dest: t.facet.solr_field }
    end
    facetable_fields << {
        source: Fields::COLLECTION,
        dest: Facet.where(name: 'Collection').first.solr_field }
    facetable_fields_to_add = facetable_fields.reject do |ff|
      current['schema']['copyFields'].
          map{ |sf| "#{sf['source']}-#{sf['dest']}" }.
          include?("#{ff['source']}-#{ff['dest']}")
    end
    post_fields('add-copy-field', facetable_fields_to_add)

    # copy various fields into a search-all field
    search_all_fields_to_add = search_all_fields.reject do |ff|
      current['schema']['copyFields'].
          map{ |sf| "#{sf['source']}-#{sf['dest']}" }.
          include?("#{ff['source']}-#{ff['dest']}")
    end
    post_fields('add-copy-field', search_all_fields_to_add)
=end
    # delete obsolete copyFields
    copy_fields_to_delete = current['schema']['copyFields'].select do |kf|
      !SCHEMA['copyFields'].map{ |sf| "#{sf['source']}#{sf['dest']}" }.
          include?("#{kf['source']}#{kf['dest']}") if SCHEMA['copyFields']
    end
    post_fields(http, url, 'delete-copy-field', copy_fields_to_delete)

    # add new copyFields
    if SCHEMA['copyFields']
      copy_fields_to_add = SCHEMA['copyFields'].reject do |kf|
        current['schema']['copyFields'].
            map{ |sf| "#{sf['source']}#{sf['dest']}" }.
            include?("#{kf['source']}#{kf['dest']}")
      end
      post_fields(http, url, 'add-copy-field', copy_fields_to_add)
    end
  end

  private

  def client
    config = PearTree::Application.peartree_config
    @client = RSolr.connect(url: config[:solr_url].chomp('/') + '/' +
        config[:solr_core]) unless @client
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
