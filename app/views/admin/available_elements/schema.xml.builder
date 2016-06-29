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

      xml.comment!('Medusa UUID of the item. REQUIRED.')
      xml.tag!('xs:element', { name: 'repositoryId', minOccurs: '1', maxOccurs: '1' }) do
        xml.tag!('xs:simpleType') do
          xml.tag!('xs:restriction', { base: 'xs:token' }) do
            xml.tag!('xs:pattern', { value: '[^\.]{0,200}' })
          end
        end
      end

      xml.comment!('Medusa UUID of the collection in which the item resides. '\
      'REQUIRED.')
      xml.tag!('xs:element', { name: 'collectionId', type: 'xs:token',
                               minOccurs: '1', maxOccurs: '1' })

      xml.comment!('repositoryId of the item\'s parent item. Should be omitted '\
      'or left empty for top-level items.')
      xml.tag!('xs:element', { name: 'parentId', type: 'xs:token',
                               minOccurs: '0', maxOccurs: '1' })

      xml.comment!('repositoryId of the item that best represents the entity, '\
      'for the purposes of e.g. rendering a thumbnail image. For example, for '\
      'a compound object, it could be the first page.')
      xml.tag!('xs:element', { name: 'representativeItemId', type: 'xs:token',
                               minOccurs: '0', maxOccurs: '1' })

      xml.comment!('Whether the item will be publicly accessible at ingest. '\
      'Will default to true if not supplied.')
      xml.tag!('xs:element', { name: 'published', type: 'xs:boolean',
                               minOccurs: '0', maxOccurs: '1' })

      xml.comment!('"Full text" of the item. Will be indexed for searching.')
      xml.tag!('xs:element', { name: 'fullText', type: 'xs:string',
                               minOccurs: '0', maxOccurs: '1' })

      xml.comment!('Page number of an item that is a child of another item, '\
      'starting at 1. Used for sorting and previous/next navigation.')
      xml.tag!('xs:element', { name: 'pageNumber', type: 'xs:positiveInteger',
                               minOccurs: '0', maxOccurs: '1' })

      xml.comment!('Subpage number of an item that is a fragment of a page, '\
      'starting at 1.')
      xml.tag!('xs:element', { name: 'subpageNumber', type: 'xs:positiveInteger',
                               minOccurs: '0', maxOccurs: '1' })

      xml.comment!('Spatial latitude in decimal degrees.')
      xml.tag!('xs:element', { name: 'latitude', type: 'xs:float',
                               minOccurs: '0', maxOccurs: '1' })

      xml.comment!('Spatial longitude in decimal degrees.')
      xml.tag!('xs:element', { name: 'longitude', type: 'xs:float',
                               minOccurs: '0', maxOccurs: '1' })

      xml.comment!('When the item was created.')
      xml.tag!('xs:element', { name: 'created', type: 'xs:dateTime',
                               minOccurs: '0', maxOccurs: '1' })

      xml.comment!('When the item was last modified.')
      xml.tag!('xs:element', { name: 'lastModified', type: 'xs:dateTime',
                               minOccurs: '0', maxOccurs: '1' })

      xml.comment!('A way of refining the type of an item, which may affect '\
      'how it is displayed.')
      xml.tag!('xs:element', { name: 'variant', minOccurs: '0', maxOccurs: '1' }) do
        xml.tag!('xs:simpleType') do
          xml.tag!('xs:restriction', { base: 'xs:token' }) do
            xml.comment!('As in a filesystem directory')
            xml.tag!('xs:enumeration', { value: 'Directory' })
            xml.comment!('As in a file on a filesystem')
            xml.tag!('xs:enumeration', { value: 'File' })
            xml.comment!('Front matter in e.g. a book')
            xml.tag!('xs:enumeration', { value: 'FrontMatter' })
            xml.comment!('As in a book or map index')
            xml.tag!('xs:enumeration', { value: 'Index' })
            xml.comment!('As in a map key')
            xml.tag!('xs:enumeration', { value: 'Key' })
            xml.comment!('As in a book page')
            xml.tag!('xs:enumeration', { value: 'Page' })
            xml.comment!('As in a title page or book cover')
            xml.tag!('xs:enumeration', { value: 'Title' })
          end
        end
      end

      xml.comment!('******************* DESCRIPTIVE ELEMENTS *******************')

      AvailableElement.all.order(:name).each do |e|
        xml.tag!('xs:element', { name: e.name, type: 'xs:string',
                                 minOccurs: '0', maxOccurs: 'unbounded' })
      end
    end
  end

end
