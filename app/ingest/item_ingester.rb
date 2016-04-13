class ItemIngester

  XML_NAMESPACES = { 'lrp' => 'http://www.library.illinois.edu/lrp/terms#' }

  ##
  # Ingests items from all metadata files (item_*.xml`) underneath the given
  # pathname.
  #
  # @param pathname [String] Root pathname to ingest
  # @return [Integer] Number of items ingested
  #
  def ingest_pathname(pathname)
    pathname = File.expand_path(pathname)
    Rails.logger.info("Ingesting content in #{pathname}...")
    count = 0
    Dir.glob(pathname + '/**/*.xml').each do |p|
      count = ingest_file(p, count)
    end
    count
  end

  ##
  # Creates a new item from the given XML document, or updates the item
  # corresponding to the item ID in the document if it already exists.
  #
  # @param xml [String] XML document string
  # @return [Item]
  #
  def ingest_xml(xml)
    doc = Nokogiri::XML(xml, &:noblanks)
    doc.encoding = 'utf-8'
    validate_document(doc, 'object.xsd')
    node = doc.xpath('//lrp:Object', XML_NAMESPACES).first
    item = Item.from_lrp_xml(node)
    existing_item = Item.find_by_repository_id(item.repository_id)
    item = existing_item if existing_item
    item.save!
    item
  end

  ##
  # @param pathname [String] File or path to validate
  # @return [Integer] Number of items validated
  #
  def validate_pathname(pathname)
    pathname = File.expand_path(pathname)
    count = 0
    if pathname.end_with?('.xml')
      count = validate_file(pathname, count)
    elsif File.directory?(pathname)
      Dir.glob(pathname + '/**/*.xml').each do |p|
        count = validate_file(p, count)
      end
    end
    count
  end

  private

  ##
  # @param pathname [String] Pathname of a metadata file.
  # @param count [Integer] Running count of files ingested; will be logged.
  # @return [Integer] The given count plus one.
  #
  def ingest_file(pathname, count = 0)
    Rails.logger.info("Ingesting #{pathname} (#{count})")
    File.open(pathname) do |content|
      doc = Nokogiri::XML(content, &:noblanks)
      doc.encoding = 'utf-8'
      validate_document(doc, 'object.xsd')
      node = doc.xpath('//lrp:Object', XML_NAMESPACES).first
      Item.from_lrp_xml(node).save!
      count += 1
    end
    count
  end

  ##
  # @param doc [Nokogiri::XML::Document]
  # @param schema [String]
  # @return [void]
  # @raise [RuntimeError] If the validation fails.
  #
  def validate_document(doc, schema)
    File.open(__dir__ + '/../../public/schema/1/' + schema) do |content|
      xsd = Nokogiri::XML::Schema(content)
      xsd.validate(doc).each do |error|
        raise error.message
      end
    end
  end

  ##
  # @param pathname [String] Pathname of a metadata file.
  # @param count [Integer] Running count of files validated; will be logged.
  # @return [Integer] The given count plus one.
  # @raise [RuntimeError]
  #
  def validate_file(pathname, count = 0)
    Rails.logger.info("Validating #{pathname} (#{count})")
    File.open(pathname) do |content|
      doc = Nokogiri::XML(content, &:noblanks)
      doc.encoding = 'utf-8'
      validate_document(doc, 'object.xsd')
      count += 1
    end
    count
  end

end
