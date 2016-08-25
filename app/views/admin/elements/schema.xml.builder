# Eliminate whitespace
xml = Builder::XmlMarkup.new

xml.instruct!

xml.tag!('schema',
         { 'xmlns:xs' => 'http://www.w3.org/2001/XMLSchema',
           'xmlns:dls' => 'http://digital.library.illinois.edu/terms#',
           'targetNamespace' => 'http://digital.library.illinois.edu/terms#',
           'elementFormDefault' => 'qualified',
           'attributeFormDefault' => 'unqualified'
         }) do

  xml.tag!('xs:complexType', { name: 'Item' }) do
    xml.tag!('xs:sequence') do

      xml.comment!('******************* TECHNICAL ELEMENTS *******************')

      xml.comment!('Repository UUID of the item. REQUIRED.')
      xml.tag!('xs:element', { name: 'repositoryId', minOccurs: '1', maxOccurs: '1' }) do
        xml.tag!('xs:simpleType') do
          xml.tag!('xs:restriction', { base: 'xs:token' }) do
            xml.tag!('xs:pattern', { value: '[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}' })
          end
        end
      end

      xml.comment!('Medusa UUID of the collection in which the item resides. '\
      'REQUIRED.')
      xml.tag!('xs:element', { name: 'collectionId', minOccurs: '1', maxOccurs: '1' }) do
        xml.tag!('xs:simpleType') do
          xml.tag!('xs:restriction', { base: 'xs:token' }) do
            xml.tag!('xs:pattern', { value: '[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}' })
          end
        end
      end

      xml.comment!('repositoryId of the item\'s parent item. Should be omitted '\
      'or left empty for top-level items.')
      xml.tag!('xs:element', { name: 'parentId', minOccurs: '0', maxOccurs: '1' }) do
        xml.tag!('xs:simpleType') do
          xml.tag!('xs:restriction', { base: 'xs:token' }) do
            xml.tag!('xs:pattern', { value: '[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}' })
          end
        end
      end

      xml.comment!('repositoryId of the item that best represents the entity, '\
      'for the purposes of e.g. rendering a thumbnail image. For example, for '\
      'a compound object, it could be the first page.')
      xml.tag!('xs:element', { name: 'representativeItemId', minOccurs: '0', maxOccurs: '1' }) do
        xml.tag!('xs:simpleType') do
          xml.tag!('xs:restriction', { base: 'xs:token' }) do
            xml.tag!('xs:pattern', { value: '[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}' })
          end
        end
      end

      xml.comment!('Whether the item is publicly accessible. Will default to '\
      'true if not supplied.')
      xml.tag!('xs:element', { name: 'published', type: 'xs:boolean',
                               minOccurs: '0', maxOccurs: '1' })

      xml.comment!('Rights statement URI, typically from RightsStatement.org.')
      xml.tag!('xs:element', { name: 'rightsStatementUri', type: 'xs:anyURI',
                               minOccurs: '0', maxOccurs: '1' })

      xml.comment!('"Full text" of the item, which will viewable and indexed '\
      'for searching.')
      xml.tag!('xs:element', { name: 'fullText', type: 'xs:string',
                               minOccurs: '0', maxOccurs: '1' })

      xml.comment!('Page number of an item with a variant of "Page," '\
      'starting at 1. Used for sorting and previous/next navigation.')
      xml.tag!('xs:element', { name: 'pageNumber', type: 'xs:positiveInteger',
                               minOccurs: '0', maxOccurs: '1' })

      xml.comment!('Subpage number of an item that is a fragment of a page, '\
      'starting at 1.')
      xml.tag!('xs:element', { name: 'subpageNumber', type: 'xs:positiveInteger',
                               minOccurs: '0', maxOccurs: '1' })

      xml.comment!('Spatial longitude in decimal degrees.')
      xml.tag!('xs:element', { name: 'longitude', type: 'xs:float',
                               minOccurs: '0', maxOccurs: '1' })

      xml.comment!('Spatial latitude in decimal degrees.')
      xml.tag!('xs:element', { name: 'latitude', type: 'xs:float',
                               minOccurs: '0', maxOccurs: '1' })

      xml.comment!('A way of refining the type of an item, which may affect '\
      'how it is displayed. (Generally, "compound object" pages require '\
      'a value of "Page".)')
      xml.tag!('xs:element', { name: 'variant', minOccurs: '0', maxOccurs: '1' }) do
        xml.tag!('xs:simpleType') do
          xml.tag!('xs:restriction', { base: 'xs:token' }) do
            Item::Variants::constants.each do |const|
              xml.tag!('xs:enumeration', { value: const.to_s.downcase.camelize })
            end
          end
        end
      end

      xml.comment!('******************* DESCRIPTIVE ELEMENTS *******************')

      Element.all.order(:name).each do |e|
        xml.tag!('xs:element', { name: e.name, type: 'xs:string',
                                 minOccurs: '0', maxOccurs: 'unbounded' })
      end
    end
  end

end
