class Item < Entity

  attr_accessor :collection_id # String
  attr_accessor :parent_id # String

  ##
  # @return [Hash]
  #
  def to_solr
    doc = super
    doc['collection_si'] = self.collection_id
    doc['parent_si'] = self.parent_id
    #doc['date_dti'] = self.date.iso8601 if self.date
    doc['access_master_media_type_si'] = self.access_master_media_type
    doc['access_master_pathname_si'] = self.access_master_pathname
    doc['full_text_txtim'] = self.full_text
    doc['preservation_master_media_type_si'] = self.preservation_master_media_type
    doc['preservation_master_pathname_si'] = self.preservation_master_pathname
    doc
  end

end
