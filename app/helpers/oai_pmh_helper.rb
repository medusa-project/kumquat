module OaiPmhHelper

  ##
  # @param identifier [String]
  # @param host [String]
  # @return [Item]
  #
  def item_for_oai_pmh_identifier(identifier, host)
    parts = identifier.split(':')
    id = parts.pop
    return nil if parts.join(':') != "oai:#{host}"
    Item.where(repository_id: id, published: true).limit(1).first
  end

  ##
  # @param item [Item]
  # @param xml [XML::Builder]
  # @return [void]
  #
  def oai_pmh_elements_for(item, xml)
    item.elements.each do |element|
      # oai_dc supports only unqualified DC.
      dc_element = item.collection.metadata_profile.elements.
          select{ |e| e.name == element.name }.first&.dc_map
      if dc_element.present? and element.value.present?
        xml.tag!("dc:#{dc_element}", element.value)
      end
    end
    # Add a dc:identifier element containing the item URI (IMET-391)
    xml.tag!('dc:identifier', item_url(item))
  end

  ##
  # @param item [Item]
  # @param host [String]
  # @return [String]
  #
  def oai_pmh_identifier_for(item, host)
    # see section 2.4: http://www.openarchives.org/OAI/openarchivesprotocol.html
    "oai:#{host}:#{item.repository_id}"
  end

end