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
  # This element set is based on CONTENTdm's `oai_qdc` format, containing a mix
  # of `dc` and `dcterms` elements, depending on whether an element is
  # qualified or not, and also adding a few more elements by request of staff
  # involved with harvesting at UIUC Library.
  #
  # @param item [Item]
  # @param xml [XML::Builder]
  # @return [void]
  #
  def oai_pmh_idhh_elements_for(item, xml)
    profile = item.collection.metadata_profile
    xml.tag!('oai_idhh:idhh', {
        'xmlns:oai_idhh':     OaiPmhController::IDHH_METADATA_FORMAT[:uri],
        'xmlns:dc':           'http://purl.org/dc/elements/1.1/',
        'xmlns:dcterms':      'http://purl.org/dc/terms/',
        'xmlns:edm':          'http://www.europeana.eu/schemas/edm/',
        'xmlns:xsi':          'http://www.w3.org/2001/XMLSchema-instance'
    }) do
      item.elements_in_profile_order(only_visible: true).
          select{ |e| e.value.present? }.each do |ie|
        profile_element = profile.elements.select{ |pe| pe.name == ie.name }.first
        if profile_element
          dcterms_element = profile_element.dcterms_map
          if dcterms_element.present?
            dc_element = DublinCoreElement.all.select{ |e| e.name == dcterms_element }.first
            if dc_element
              xml.tag!("dc:#{dc_element.name}", ie.value)

              # If the element is `rights` and the ItemElement contains a URI,
              # add another element for that. (Requested by
              # lampron2@illinois.edu)
              if dc_element.name == 'rights' and ie.uri.present?
                xml.tag!("dc:#{dc_element.name}", ie.uri)
              end
            else
              xml.tag!("dcterms:#{dcterms_element}", ie.value)
            end
          end
        end
      end

      # Add a dcterms:identifier element containing the item URI (IMET-391)
      xml.tag!('dc:identifier', item_url(item))

      # Add a thumbnail URI, if the item has a representative image. This was
      # requested by mhan3@illinois.edu.
      image_url = item_image_url(item, :full, 150, :jpg)
      xml.tag!('edm:preview', { 'xmlns:edm' => 'http://www.europeana.eu/schemas/edm/' }, image_url) if image_url

      # Add a link to the IIIF presentation manifest.
      xml.tag!('dcterms:isReferencedBy', item_iiif_manifest_url(item))
    end
  end

  ##
  # This element set is optimized for harvesting into the UIUC Library's Primo
  # catalog.
  #
  # @param item [Item]
  # @param xml [XML::Builder]
  # @return [void]
  #
  def oai_pmh_primo_elements_for(item, xml)
    profile = item.collection.metadata_profile
    xml.tag!('oai_primo:primo', {
        "xmlns:oai_primo":    OaiPmhController::PRIMO_METADATA_FORMAT[:uri],
        'xmlns:dc':           'http://purl.org/dc/elements/1.1/',
        'xmlns:dcterms':      'http://purl.org/dc/terms/',
        'xmlns:xsi':          'http://www.w3.org/2001/XMLSchema-instance'
    }) do
      item.elements_in_profile_order(only_visible: true).
          select{ |e| e.value.present? }.each do |ie|
        profile_element = profile.elements.select{ |pe| pe.name == ie.name }.first
        if profile_element
          dcterms_element = profile_element.dcterms_map
          if dcterms_element.present?
            dc_element = DublinCoreElement.all.select{ |e| e.name == dcterms_element }.first
            if dc_element
              xml.tag!("dc:#{dc_element.name}", ie.value)
              if dc_element.name == 'rights' and ie.uri.present?
                xml.tag!("dc:#{dc_element.name}", ie.uri)
              end
            else
              xml.tag!("dcterms:#{dcterms_element}", ie.value)
            end
          end
        end
      end
      xml.tag!('dc:identifier', item_url(item))
      xml.tag!('dcterms:isReferencedBy', item_iiif_manifest_url(item))
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