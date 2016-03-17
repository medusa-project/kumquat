class Collection < Entity

  ##
  # @param doc [Nokogiri::XML::Document]
  # @return [Collection]
  #
  def self.from_solr(doc)
    col = Collection.new
    col.id = doc[Solr::Fields::ID]
    col.bib_id = doc[Solr::Fields::BIB_ID]
    if doc[Solr::Fields::CREATED]
      col.created = DateTime.parse(doc[Solr::Fields::CREATED])
    end
    if doc[Solr::Fields::LAST_INDEXED]
      col.last_indexed = DateTime.parse(doc[Solr::Fields::LAST_INDEXED])
    end
    if doc[Solr::Fields::LAST_MODIFIED]
      col.last_modified = DateTime.parse(doc[Solr::Fields::LAST_MODIFIED])
    end
    col.metadata_pathname = doc[Solr::Fields::METADATA_PATHNAME]
    col.published = doc[Solr::Fields::PUBLISHED]
    col.representative_item_id = doc[Solr::Fields::REPRESENTATIVE_ITEM_ID]
    col.subclass = doc[Solr::Fields::SUBCLASS]
    col.web_id = doc[Solr::Fields::WEB_ID]

    # descriptive metadata
    doc.keys.select{ |k| k.start_with?(Element.solr_prefix) and
        k.end_with?(Element.solr_suffix) }.each do |key|
      filtered_key = key.gsub(Element.solr_prefix, '').chomp(Element.solr_suffix)
      doc[key].each do |value|
        e = Element.named(filtered_key)
        e.value = value
        col.metadata << e
      end
    end

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
  # @return [Medusa::Collection,nil]
  #
  def medusa_collection
    medusa_id = self.collection_def.medusa_id
    if medusa_id
      return Medusa::Collection.new{ self.id = medusa_id }
    end
    nil
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
