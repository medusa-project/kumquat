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
          'uiuc' => 'http://www.library.illinois.edu/terms#'
      }

      entity = self.new

      # id
      id = node.xpath('uiuc:identifier', namespaces).first
      entity.id = id.content.strip if id
      if !id or entity.id.blank?
        raise "uiuc:identifier is missing or invalid for entity in "\
        "#{metadata_pathname}"
      end

      # title
      title = node.xpath('dc:title', namespaces).first
      title = node.xpath('dcterms:title', namespaces).first unless title
      entity.title = title ? title.content.strip : entity.id

      # web ID
      web_id = node.xpath('uiuc:webID', namespaces).first
      entity.web_id = web_id ? web_id.content.strip : entity.id

      if entity.kind_of?(Item)
        # collection
        col = node.xpath('uiuc:collection', namespaces).first
        entity.collection_id = col.content.strip if col
        if !col or entity.collection_id.blank?
          raise "uiuc:collection is missing or invalid for item with "\
          "uiuc:identifier #{entity.id} (#{metadata_pathname})"
        end

        # parent item
        parent = node.xpath('uiuc:hasParent', namespaces).first
        entity.parent_id = parent.content.strip if parent

        # access master
        am = node.xpath('uiuc:accessMasterPathname', namespaces).first
        if am
          entity.access_master_pathname = File.dirname(metadata_pathname) +
              File::SEPARATOR + am.content.strip
          unless File.exist?(entity.access_master_pathname)
            raise "uiuc:accessMasterPathname refers to a missing file for "\
            "item with uiuc:identifier #{entity.id} (#{metadata_pathname})"
          end
          mt = node.xpath('uiuc:accessMasterMediaType', namespaces).first
          entity.access_master_media_type = mt.content.strip if mt
        end

        # date
        date = node.xpath('dc:date', namespaces).first
        date = node.xpath('dcterms:date', namespaces).first unless date
        if date
          # TODO: gonna have to parse this carefully
          #entity.date = Date.parse(date.content.strip)
        end

        # full text
        id = node.xpath('uiuc:fullText', namespaces).first
        entity.full_text = id.content.strip if id

        # preservation master
        pm = node.xpath('uiuc:preservationMasterPathname', namespaces).first
        if pm
          entity.preservation_master_pathname = File.dirname(metadata_pathname) +
              File::SEPARATOR + pm.content.strip
          unless File.exist?(entity.preservation_master_pathname)
            raise "uiuc:preservationMasterPathname refers to a missing file "\
            "for item with uiuc:identifier #{entity.id} (#{metadata_pathname})"
          end
          mt = node.xpath('uiuc:preservationMasterMediaType', namespaces).first
          entity.preservation_master_media_type = mt.content.strip if mt
        end
      end

      entity.instance_variable_set('@persisted', true)
      entity
    end

    def from_solr(doc)
      class_field = PearTree::Application.peartree_config[:solr_class_field]
      class_ = doc[class_field].constantize
      entity = class_.new
      entity.id = doc['id']
      entity.access_master_media_type = doc['access_master_media_type_si']
      entity.access_master_pathname = doc['access_master_pathname_si']
      entity.full_text = doc['full_text_txtim']
      entity.access_master_media_type = doc['access_master_media_type_si']
      entity.preservation_master_pathname = doc['preservation_master_pathname_si']
      entity.title = doc['title_txti']
      entity.web_id = doc['web_id_si']
      entity.instance_variable_set('@persisted', true)
      entity
    end

  end

end
