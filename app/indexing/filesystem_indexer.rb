##
# Indexing tool that scans a filesystem tree for PearTree AIP files and
# indexes them in Solr.
#
# The indexer only indexes content in AIP files -- it does not extract any
# content dynamically, such as getting an image's actual dimensions, or
# extracting full text, or inferring media type, etc. That information must be
# pre-encoded in the AIP files. Reason being, the indexer needs to run as fast
# as possible, as it will eventually need to scan through millions of files in
# a reasonable amount of time.
#
class FilesystemIndexer

  ##
  # @param collection [MedusaCollection] Medusa collection
  # @return [Integer] Number of items indexed
  #
  def index(collection)
    file_group = collection.collection_def.medusa_metadata_file_group
    cfs_dir = file_group.cfs_directory
    pathname = cfs_dir.pathname
    index_directory(pathname)
  end

  ##
  # @param pathname [String] File or path to validate
  # @return [Integer] Number of items validated
  #
  def validate(pathname)
    count = 0
    # If pathname is a file...
    if pathname.end_with?('.xml') and %w(item).include?(entity(pathname))
      count = validate_file(pathname, count)
    else
      # Pathname is a directory
      count = validate_directory(pathname)
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
  # Indexes all metadata files (item_*.xml`) within the given pathname.
  #
  # @param pathname [String] Root pathname to index
  # @return [Integer] Number of items indexed
  #
  def index_directory(pathname)
    Rails.logger.info("Indexing #{pathname}...")
    count = 0
    Dir.glob(pathname + '/**/*.xml').each do |p|
      if %w(item).include?(entity(p)) and !p.include?('/source')
        count = index_file(p, count)
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
    Rails.logger.info("Indexing #{pathname} (#{count})")
    File.open(pathname) do |content|
      doc = Nokogiri::XML(content, &:noblanks)
      doc.encoding = 'utf-8'
      case entity
        when 'item'
          validate_document(doc, 'object.xsd')
          node = doc.xpath('//lrp:Object', namespaces).first
          entity = entity_class.from_lrp_xml(node, pathname)
          entity.save
          count += 1
        else
          raise "Encountered unknown entity (#{entity_class}) in #{pathname}"
      end
    end
    count
  end

  ##
  # Validates all metadata files within the given pathname.
  #
  # @param root_pathname [String] Root pathname to validate
  # @return [Integer] Number of items validated
  #
  def validate_directory(root_pathname)
    count = 0
    Dir.glob(root_pathname + '/**/*.xml').each do |pathname|
      if %w(item).include?(entity(pathname))
        count = validate_file(pathname, count)
      end
    end
    count
  end

  ##
  # @param pathname [String] Pathname of a metadata file.
  # @param count [Integer] Running count of files validated; will be logged.
  # @return [Integer] The given count plus one.
  # @raise [RuntimeError]
  #
  def validate_file(pathname, count = 0)
    entity = entity(pathname).singularize
    entity_class = entity.capitalize.constantize

    Rails.logger.info("Validating #{pathname} (#{count})")
    File.open(pathname) do |content|
      doc = Nokogiri::XML(content, &:noblanks)
      doc.encoding = 'utf-8'
      case entity
        when 'item'
          validate_document(doc, 'object.xsd')
          count += 1
        else
          raise "Encountered unknown entity (#{entity_class}) in #{pathname}"
      end
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

end
