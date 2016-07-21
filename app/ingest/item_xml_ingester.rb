class ItemXmlIngester

  SCHEMA_VERSIONS = [3]

  XML_V3_NAMESPACES = { 'dls' => 'http://digital.library.illinois.edu/terms#' }

  ##
  # Creates a new item from the given XML document, or updates the item
  # corresponding to the item ID in the document if it already exists.
  #
  # @param xml [String] XML document string
  # @param schema_version [Integer] XML schema version
  # @return [Item]
  #
  def ingest_xml(xml, schema_version)
    raise 'Invalid schema version' unless
        SCHEMA_VERSIONS.include?(schema_version)

    doc = Nokogiri::XML(xml, &:noblanks)
    doc.encoding = 'utf-8'
    validate_document(doc, 'object.xsd', schema_version)
    if schema_version == 3
      node = doc.xpath('//dls:Object', XML_V3_NAMESPACES).first
      # If an item with the same repository ID already exists, update it.
      # Otherwise, create a new item and save it.
      repository_id = node.xpath('dls:repositoryId', XML_V3_NAMESPACES).
          first.content.strip
    end

    item = nil
    if repository_id
      item = Item.find_by_repository_id(repository_id)
      if item
        item.update_from_xml(node, schema_version)
      end
    end
    unless item
      item = Item.from_dls_xml(node, schema_version)
    end
    item
  end

  private

  ##
  # @param pathname [String] Pathname of a metadata file.
  # @param schema_version [Integer]
  # @param count [Integer] Running count of files ingested; will be logged.
  # @return [Integer] The given count plus one.
  #
  def ingest_file(pathname, schema_version, count = 0)
    Rails.logger.info("Ingesting #{pathname} (#{count})")
    ingest_xml(File.read(pathname), schema_version)
    count += 1
    count
  end

  ##
  # @param doc [Nokogiri::XML::Document]
  # @param schema [String]
  # @param schema_version [Integer]
  # @return [void]
  # @raise [RuntimeError] If the validation fails.
  #
  def validate_document(doc, schema, schema_version)
    schema_path = sprintf('%s/public/schema/%d/%s',
                          Rails.root, schema_version, schema)
    xsd = Nokogiri::XML::Schema(File.read(schema_path))
    xsd.validate(doc).each do |error|
      raise error.message
    end
  end

  ##
  # @param pathname [String] Pathname of a metadata file.
  # @param schema_version [Integer]
  # @param count [Integer] Running count of files validated; will be logged.
  # @return [Integer] The given count plus one.
  # @raise [RuntimeError]
  #
  def validate_file(pathname, schema_version, count = 0)
    Rails.logger.info("Validating #{pathname} (#{count})")

    doc = Nokogiri::XML(File.read(pathname), &:noblanks)
    doc.encoding = 'utf-8'
    validate_document(doc, 'object.xsd', schema_version)
    count += 1
    count
  end

end
