module Deserialization

  def self.included(mod)
    mod.extend ClassMethods
  end

  module ClassMethods

    ##
    # @param [Nokogiri::XML::Node] node
    # @param [String] metadata_pathname
    # @return [Entity]
    # @raises [RuntimeError]
    #
    def from_dc_xml(node, metadata_pathname)
      namespaces = {
          'dc' => 'http://purl.org/dc/elements/1.1/',
          'dcterms' => 'http://purl.org/dc/terms/',
          'lrp' => 'http://www.library.illinois.edu/lrp/terms#'
      }

      entity = self.new

      # id
      id = node.xpath('lrp:identifier', namespaces).first
      entity.id = id.content.strip if id
      if !id or entity.id.blank?
        raise "lrp:identifier is missing or invalid for entity in "\
        "#{metadata_pathname}"
      end

      # subtitle
      subtitle = node.xpath('dcterms:alternative', namespaces).first
      entity.subtitle = subtitle.content.strip if subtitle

      # title
      title = node.xpath('dc:title', namespaces).first
      title = node.xpath('dcterms:title', namespaces).first unless title
      entity.title = title ? title.content.strip : entity.id

      # published
      entity.published = node.xpath('lrp:published', namespaces).first.present?

      # web ID
      web_id = node.xpath('lrp:webID', namespaces).first
      entity.web_id = web_id ? web_id.content.strip : entity.id

      if entity.kind_of?(Item)
        # collection
        col = node.xpath('lrp:collection', namespaces).first
        entity.collection_id = col.content.strip if col
        if !col or entity.collection_id.blank?
          raise "lrp:collection is missing or invalid for item with "\
          "lrp:identifier #{entity.id} (#{metadata_pathname})"
        end

        # parent item
        parent = node.xpath('lrp:hasParent', namespaces).first
        entity.parent_id = parent.content.strip if parent

        # access master (pathname)
        am = node.xpath('lrp:accessMasterPathname', namespaces).first
        if am
          bs = Bytestream.new
          bs.type = Bytestream::Type::ACCESS_MASTER
          bs.pathname = File.dirname(metadata_pathname) + File::SEPARATOR +
              am.content.strip
          unless File.exist?(bs.pathname)
            raise "lrp:accessMasterPathname refers to a missing file for "\
            "item with lrp:identifier #{entity.id} (#{metadata_pathname})"
          end
          # media type
          mt = node.xpath('lrp:accessMasterMediaType', namespaces).first
          if mt
            bs.media_type = mt.content.strip
          else
            bs.detect_media_type
          end
          bs.read_dimensions
          entity.bytestreams << bs
        else # access master (URL)
          am = node.xpath('lrp:accessMasterURL', namespaces).first
          if am
            bs = Bytestream.new
            bs.type = Bytestream::Type::ACCESS_MASTER
            bs.url = am.content.strip
            # media type
            mt = node.xpath('lrp:accessMasterMediaType', namespaces).first
            if mt
              bs.media_type = mt.content.strip
            else
              bs.detect_media_type
            end
            #bs.read_dimensions
            entity.bytestreams << bs
          end
        end

        # date
        date = node.xpath('dc:date', namespaces).first
        date = node.xpath('dcterms:date', namespaces).first unless date
        if date
          # TODO: gonna have to parse this carefully
          #entity.date = Date.parse(date.content.strip)
        end

        # full text
        id = node.xpath('lrp:fullText', namespaces).first
        entity.full_text = id.content.strip if id

        # preservation master (pathname)
        pm = node.xpath('lrp:preservationMasterPathname', namespaces).first
        if pm
          bs = Bytestream.new
          bs.type = Bytestream::Type::PRESERVATION_MASTER
          bs.pathname = File.dirname(metadata_pathname) + File::SEPARATOR +
              pm.content.strip
          unless File.exist?(bs.pathname)
            raise "lrp:preservationMasterPathname refers to a missing file "\
            "for item with lrp:identifier #{entity.id} (#{metadata_pathname})"
          end
          mt = node.xpath('lrp:preservationMasterMediaType', namespaces).first
          if mt
            bs.media_type = mt.content.strip
          else
            bs.detect_media_type
          end
          bs.read_dimensions
          entity.bytestreams << bs
        else # preservation master (URL)
          pm = node.xpath('lrp:preservationMasterURL', namespaces).first
          if pm
            bs = Bytestream.new
            bs.type = Bytestream::Type::ACCESS_MASTER
            bs.url = pm.content.strip
            # media type
            mt = node.xpath('lrp:preservationMasterMediaType', namespaces).first
            if mt
              bs.media_type = mt.content.strip
            else
              bs.detect_media_type
            end
            #bs.read_dimensions
            entity.bytestreams << bs
          end
        end
      end

      entity.instance_variable_set('@persisted', true)
      entity
    end

  end

end
