class ItemIngester

  SCHEMA_VERSIONS = [1, 2]

  XML_V1_NAMESPACE = { 'lrp' => 'http://www.library.illinois.edu/lrp/terms#' }
  XML_V2_NAMESPACE = { 'dls' => 'http://digital.library.illinois.edu/terms#' }

  ##
  # Ingests items from all metadata files (item_*.xml`) underneath the given
  # pathname.
  #
  # @param pathname [String] Root pathname to ingest
  # @param schema_version [Integer] Version of the XML Schema to use to
  #                                 validate the document.
  # @return [Integer] Number of items ingested
  #
  def ingest_pathname(pathname, schema_version)
    raise 'Invalid schema version' unless
        SCHEMA_VERSIONS.include?(schema_version)

    pathname = File.expand_path(pathname)
    Rails.logger.info("Ingesting content in #{pathname}...")
    count = 0
    Dir.glob(pathname + '/**/*.xml').each do |p|
      count = ingest_file(p, schema_version, count)
    end
    count
  end

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
    if schema_version == 1
      node = doc.xpath('//lrp:Object', XML_V1_NAMESPACE).first
      # If an item with the same repository ID already exists, update it.
      # Otherwise, create a new item and save it.
      repository_id = node.xpath('lrp:repositoryId', XML_V1_NAMESPACE).
          first.content.strip
    else
      node = doc.xpath('//dls:Object', XML_V2_NAMESPACE).first
      # If an item with the same repository ID already exists, update it.
      # Otherwise, create a new item and save it.
      repository_id = node.xpath('dls:repositoryId', XML_V2_NAMESPACE).
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

  ##
  # @param pathname [String] File or path to validate
  # @param schema_version [Integer]
  # @return [Integer] Number of items validated
  #
  def validate_pathname(pathname, schema_version)
    raise 'Invalid schema version' unless
        SCHEMA_VERSIONS.include?(schema_version)
    pathname = File.expand_path(pathname)
    count = 0
    if pathname.end_with?('.xml')
      count = validate_file(pathname, schema_version, count)
    elsif File.directory?(pathname)
      Dir.glob(pathname + '/**/*.xml').each do |p|
        count = validate_file(p, schema_version, count)
      end
    end
    count
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
    File.open(pathname) do |content|
      ingest_xml(content, schema_version)
      count += 1
    end
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
    schema_path = sprintf('%s/../../public/schema/%d/%s',
                          __dir__, schema_version, schema)
    File.open(schema_path) do |content|
      xsd = Nokogiri::XML::Schema(content)
      xsd.validate(doc).each do |error|
        raise error.message
      end
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
    File.open(pathname) do |content|
      doc = Nokogiri::XML(content, &:noblanks)
      doc.encoding = 'utf-8'
      validate_document(doc, 'object.xsd', schema_version)
      count += 1
    end
    count
  end

end
