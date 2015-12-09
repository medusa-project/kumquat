class Indexer

  ##
  # Indexes all metadata files (`collection.xml` or `item_*.xml`) within the
  # given pathname.
  #
  # @param [String] root_pathname Root pathname to index
  # @return [void]
  #
  def index_all(root_pathname)
    count = 0
    Dir.glob(root_pathname + '/**/*').select{ |file| File.file?(file) }.each do |pathname|
      if %w(collection item).include?(entity(pathname))
        count = index_file(pathname, count)
      end
    end
  end

  ##
  # @param pathname [String] Pathname of a metadata file.
  # @param count [Integer] Running count of files indexed; will be logged.
  # @return [Integer] The given count plus one.
  # @raise [RuntimeError]
  #
  def index_file(pathname, count = 0)
    entity = entity(pathname).singularize
    entity_class = entity.capitalize.constantize

    namespaces = { 'lrp' => 'http://www.library.illinois.edu/lrp/terms#' }
    File.open(pathname) do |content|
      Rails.logger.debug("Indexing #{pathname} (#{count})")
      doc = Nokogiri::XML(content, &:noblanks)
      doc.encoding = 'utf-8'
      case entity
        when 'item'
          validate(doc, 'object.xsd')
          node = doc.xpath('//lrp:Object', namespaces).first
          entity = entity_class.from_lrp_xml(node, pathname)
          entity.save
          count += 1
        when 'collection'
          validate(doc, 'collection.xsd')
          node = doc.xpath('//lrp:Collection', namespaces).first
          entity = entity_class.from_lrp_xml(node, pathname)
          entity.save
          count += 1
        else
          raise "Encountered unknown entity (#{entity_class}) in #{pathname}"
      end
    end
    count
  end

  private

  ##
  # @param [String] pathname
  # @return [String] Name of one of the [Entity] subclasses, singular or plural
  #
  def entity(pathname)
    begin
      return pathname.split(File::SEPARATOR).last.split('.').first.split('_').first
    rescue NameError
      # noop
    end
  end

  ##
  # @param doc [Nokogiri::XML::Document]
  # @param schema [String]
  # @return [void]
  # @raise [RuntimeError] If the validation fails.
  #
  def validate(doc, schema)
    xsd = Nokogiri::XML::Schema(
        File.open(__dir__ + '/../../public/schema/1/' + schema))
    xsd.validate(doc).each do |error|
      raise error.message
    end
  end

end
