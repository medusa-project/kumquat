##
# Indexing tool that scans a filesystem for PearTree AIP files and indexes them
# in Solr. Typically invoked from a Rake task.
#
# The indexer only indexes content in AIP files -- it does not extract any
# content dynamically, such as getting an image's actual dimensions, or
# extracting full text, or inferring media type, etc. That information must be
# pre-encoded in the AIP files. Reason being, the indexer needs to run as fast
# as possible, as it will eventually need to scan through millions of files in
# a reasonable amount of time.
#
class Indexer

  ##
  # @param pathname [String] File or path to index
  # @return [Integer] Number of items indexed
  #
  def index(pathname)
    count = 0
    # If pathname is a file...
    if pathname.end_with?('.xml') and
        %w(collection item).include?(entity(pathname))
      count = index_file(pathname, count)
    else
      # Pathname is a directory
      count = index_directory(pathname)
    end
    count
  end

  ##
  # Indexes all metadata files (`collection.xml` or `item_*.xml`) within the
  # given pathname.
  #
  # @param root_pathname [String] Root pathname to index
  # @return [Integer] Number of items indexed
  #
  def index_directory(root_pathname)
    count = 0
    Dir.glob(root_pathname + '/**/*').select{ |file| File.file?(file) }.each do |pathname|
      if %w(collection item).include?(entity(pathname))
        count = index_file(pathname, count)
      end
    end
    count
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
          validate_document(doc, 'object.xsd')
          node = doc.xpath('//lrp:Object', namespaces).first
          entity = entity_class.from_lrp_xml(node, pathname)
          entity.save
          count += 1
        when 'collection'
          validate_document(doc, 'collection.xsd')
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

  def validate(pathname)
    entity = entity(pathname).singularize
    entity_class = entity.capitalize.constantize
    File.open(pathname) do |content|
      doc = Nokogiri::XML(content, &:noblanks)
      doc.encoding = 'utf-8'
      case entity
        when 'item'
          validate_document(doc, 'object.xsd')
        when 'collection'
          validate_document(doc, 'collection.xsd')
        else
          raise "Encountered unknown entity (#{entity_class}) in #{pathname}"
      end
    end
    true
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
  def validate_document(doc, schema)
    xsd = Nokogiri::XML::Schema(
        File.open(__dir__ + '/../../public/schema/1/' + schema))
    xsd.validate(doc).each do |error|
      raise error.message
    end
  end

end
