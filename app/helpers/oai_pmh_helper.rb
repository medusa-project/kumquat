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
  def oai_pmh_dc_elements_for(item, xml)
    xml.tag!('oai_dc:dc', {
        'xmlns:oai_dc' => 'http://www.openarchives.org/OAI/2.0/oai_dc/',
        'xmlns:dc' => 'http://purl.org/dc/elements/1.1/',
        'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
        'xsi:schemaLocation' => 'http://www.openarchives.org/OAI/2.0/oai_dc/ '\
                  'http://www.openarchives.org/OAI/2.0/oai_dc.xsd'
    }) do
      item.elements_in_profile_order.select{ |e| e.value.present? }.each do |ie|
        # oai_dc supports only unqualified DC.
        dc_element = item.collection.metadata_profile.elements.
            select{ |pe| pe.name == ie.name }.first&.dc_map
        xml.tag!("dc:#{dc_element}", ie.value) if dc_element.present?
      end
      # Add a dc:identifier element containing the item URI (IMET-391)
      xml.tag!('dc:identifier', item_url(item))
    end
  end

  ##
  # @param item [Item]
  # @param xml [XML::Builder]
  # @return [void]
  #
  def oai_pmh_qdc_elements_for(item, xml)
    xml.tag!('oai_qdc:qdc', {
        'xmlns:oai_qdc' => 'http://oclc.org/appqualifieddc/',
        'xmlns:dcterms' => 'http://purl.org/dc/terms/',
        'xmlns:dc' => 'http://purl.org/dc/elements/1.1/',
        'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
        'xsi:schemaLocation' => 'http://oclc.org/appqualifieddc/ '\
                      'http://dublincore.org/schemas/xmls/qdc/2003/04/02/appqualifieddc.xsd'
    }) do
      item.elements_in_profile_order.select{ |e| e.value.present? }.each do |ie|
        # oai_dc supports only unqualified DC.
        dc_element = item.collection.metadata_profile.elements.
            select{ |pe| pe.name == ie.name }.first&.dc_map
        xml.tag!("dcterms:#{dc_element}", ie.value) if dc_element.present?
      end
      # Add a dcterms:identifier element containing the item URI (IMET-391)
      xml.tag!('dcterms:identifier', item_url(item))
    end
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