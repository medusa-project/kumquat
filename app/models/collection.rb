class Collection < Entity

  ##
  # @param doc [Nokogiri::XML::Document]
  # @return [Collection]
  #
  def self.from_solr(doc)
    col = Collection.new
    col.id = doc[Solr::Fields::ID]
    if doc[Solr::Fields::CREATED]
      col.created = DateTime.parse(doc[Solr::Fields::CREATED])
    end
    if doc[Solr::Fields::LAST_INDEXED]
      col.last_indexed = DateTime.parse(doc[Solr::Fields::LAST_INDEXED])
    end
    if doc[Solr::Fields::LAST_MODIFIED]
      col.last_modified = DateTime.parse(doc[Solr::Fields::LAST_MODIFIED])
    end
    col.published = doc[Solr::Fields::PUBLISHED]
    col.representative_item_id = doc[Solr::Fields::REPRESENTATIVE_ITEM_ID]
    col.title = doc[Solr::Fields::TITLE]
    col.web_id = doc[Solr::Fields::WEB_ID]

    # descriptive metadata
    doc.keys.select{ |k| k.start_with?('metadata_') }.each do |key|
      filtered_key = key.gsub('metadata_', '').chomp('_txtim')
      doc[key].each do |value|
        e = Element.named(filtered_key)
        e.value = value
        col.metadata << e
      end
    end
=begin TODO: give technical metadata a field prefix, otherwise this is too error-prone
    # technical metadata
    doc.keys.reject{ |k| k.start_with?('metadata_') }.each do |key|
      if doc[key].respond_to?(:each)
        doc[key].each do |value|
          e = Element.named(key)
          e.value = value
          col.metadata << e
        end
      else
        e = Element.named(key)
        if !e
          e = Element.new
          e.type = Element::Type::TECHNICAL
          e.name = key
        end
        e.value = doc[key]
        col.metadata << e
      end
    end
=end
    col.instance_variable_set('@persisted', true)
    col
  end

  ##
  # @return [CollectionDef]
  #
  def collection_def
    unless @collection_def
      @collection_def = CollectionDef.find_by_repository_id(self.id) ||
          CollectionDef.create!(repository_id: self.id,
                                metadata_profile: MetadataProfile.find_by_default(true))
    end
    @collection_def
  end

  ##
  # @return [Integer]
  #
  def num_items
    @num_items = Item.where(Solr::Fields::COLLECTION => self.id).
        where(Solr::Fields::PARENT_ITEM => :null).count unless @num_items
    @num_items
  end

end
