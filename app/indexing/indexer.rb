class Indexer

  # Metadata filename format: {entity}_{id}.xml
  ALLOWED_ENTITIES = %w(collection item items)

  ##
  # Indexes all metadata files within the given pathname.
  #
  # @param [String] root_pathname Root pathname to index
  #
  def index_all(root_pathname)
    count = 0
    Dir.glob(root_pathname + '/**/*').select{ |file| File.file?(file) }.each do |pathname|
      count = index_file(pathname, count) if ALLOWED_ENTITIES.include?(entity(pathname))
    end
  end

  ##
  # @param pathname [String] Pathname of a metadata file.
  #
  def index_file(pathname, count)
    entity = entity(pathname).singularize
    entity_class = entity.capitalize.constantize

    namespaces = { 'lrp' => 'http://www.library.illinois.edu/lrp/terms#' }
    File.open(pathname) do |content|
      doc = Nokogiri::XML(content, &:noblanks)
      doc.encoding = 'utf-8'
      case entity
        when 'item'
          doc.xpath('//lrp:Object', namespaces).each do |node|
            entity = entity_class.from_lrp_xml(node, pathname)
            entity.save
            count += 1
            Rails.logger.debug("Indexed #{entity.id} (#{count})")
          end
        when 'collection'
          node = doc.xpath('//lrp:Collection', namespaces).first
          if node
            entity = entity_class.from_lrp_xml(node, pathname)
            entity.save
            count += 1
            Rails.logger.debug("Indexed #{entity.id} (#{count})")
          else
            raise "Collection metadata file is missing lrp:Collection "\
            "element: #{pathname}"
          end
        else
          raise "Encountered unknown entity (#{entity_class}) in #{pathname}"
      end
    end
    count
  end

  private

  ##
  # @return [String] Name of one of the `Entity` subclasses, singular or plural
  #
  def entity(pathname)
    begin
      return pathname.split(File::SEPARATOR).last.split('.').first.split('_').first
    rescue NameError
      # noop
    end
  end

end
