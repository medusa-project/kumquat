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
      item.elements_in_profile_order(only_visible: true).
          select{ |e| e.value.present? }.each do |ie|
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
  def oai_pmh_dcterms_elements_for(item, xml)
    xml.tag!('oai_dcterms:dcterms', {
        'xmlns:oai_dcterms' => 'http://oclc.org/appqualifieddc/',
        'xmlns:dcterms' => 'http://purl.org/dc/terms/',
        'xmlns:dc' => 'http://purl.org/dc/elements/1.1/',
        'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
        'xsi:schemaLocation' => 'http://oclc.org/appqualifieddc/ '\
                      'http://dublincore.org/schemas/xmls/qdc/2003/04/02/appqualifieddc.xsd'
    }) do
      item.elements_in_profile_order(only_visible: true).
          select{ |e| e.value.present? }.each do |ie|
        dc_element = item.collection.metadata_profile.elements.
            select{ |pe| pe.name == ie.name }.first&.dcterms_map
        xml.tag!("dcterms:#{dc_element}", ie.value) if dc_element.present?
      end
      # Add a dcterms:identifier element containing the item URI (IMET-391)
      xml.tag!('dcterms:identifier', item_url(item))
    end
  end

  ##
  # Using a metadataPrefix of oai_qdc, the CONTENTdm OAI_PMH endpoint returns
  # a mix of dc: and dcterms: elements, depending on whether an element is
  # qualified or not. This method emulates that behavior.
  #
  # @param item [Item]
  # @param xml [XML::Builder]
  # @return [void]
  #
  def oai_pmh_qdc_elements_for(item, xml)
    profile = item.collection.metadata_profile
    xml.tag!('oai_qdc:qdc', {
        'xmlns:oai_qdc' => 'http://oclc.org/appqualifieddc/',
        'xmlns:dcterms' => 'http://purl.org/dc/terms/',
        'xmlns:dc' => 'http://purl.org/dc/elements/1.1/',
        'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
        'xsi:schemaLocation' => 'http://oclc.org/appqualifieddc/ '\
                      'http://dublincore.org/schemas/xmls/qdc/2003/04/02/appqualifieddc.xsd'
    }) do
      item.elements_in_profile_order(only_visible: true).
          select{ |e| e.value.present? }.each do |ie|
        profile_element = profile.elements.select{ |pe| pe.name == ie.name }.first
        if profile_element
          dc_element = profile_element.dc_map
          dcterms_element = profile_element.dcterms_map

          if dc_element.present?
            xml.tag!("dc:#{dc_element}", ie.value)
          elsif dcterms_element.present?
            xml.tag!("dcterms:#{dcterms_element}", ie.value)
          end
        end
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