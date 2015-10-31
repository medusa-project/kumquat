class Indexer

  # Metadata filename format: {entity}_{id}_{format}.{encoding}
  ALLOWED_ENTITIES = %w(collection item items)
  ALLOWED_FORMATS = %w(marc mods mets dc rdf)
  ALLOWED_ENCODINGS = %w(ttl nt xml)

  ##
  # Indexes all metadata files within the given pathname.
  #
  # @param [String] root_pathname Root pathname to index
  #
  def index_all(root_pathname)
    Dir.glob(root_pathname + '/**/*').select{ |file| File.file?(file) }.each do |pathname|
      if ALLOWED_ENTITIES.include?(entity(pathname)) and
          ALLOWED_FORMATS.include?(format(pathname)) and
          ALLOWED_ENCODINGS.include?(encoding(pathname))
        index_file(pathname)
      end
    end
  end

  ##
  # @param pathname [String] Pathname of a metadata file.
  #
  def index_file(pathname)
    encoding = encoding(pathname)
    entity = entity(pathname).singularize
    entity_class = entity.capitalize.constantize
    format = format(pathname)

    if encoding == 'xml'
      namespaces = { 'uiuc' => 'http://www.library.illinois.edu/terms#' }
      File.open(pathname) do |content|
        doc = Nokogiri::XML(content, &:noblanks)
        doc.encoding = 'utf-8'
        if format == 'dc'
          case entity
            when 'item'
              doc.xpath('//uiuc:Object', namespaces).each do |node|
                entity = entity_class.from_dc_xml(node, pathname)
                entity.index_in_solr
              end
            when 'collection'
              node = doc.xpath('//uiuc:Collection', namespaces).first
              if node
                entity = entity_class.from_dc_xml(node, pathname)
                entity.index_in_solr
              else
                raise "Collection metadata file is missing uiuc:Collection "\
                "element: #{pathname}"
              end
            else
              raise "Encountered unknown entity (#{entity_class}) in #{pathname}"
          end
        end
      end
    end
  end

  private

  def encoding(pathname)
    pathname.split('.').last
  end

  ##
  # @return [String] Name of one of the `Entity` subclasses, singular or plural
  #
  def entity(pathname)
    begin
      return pathname.split(File::SEPARATOR).last.split('_').first
    rescue NameError
      # noop
    end
  end

  def format(pathname)
    pathname.split('.').first.split('_').last
  end

end
