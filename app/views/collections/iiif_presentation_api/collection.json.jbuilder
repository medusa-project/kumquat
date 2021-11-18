# Metadata about this file
json.set! '@context', 'http://iiif.io/api/presentation/2/context.json'
json.set! '@id', collection_iiif_presentation_url(@collection)
json.set! '@type', 'sc:Collection'

# Descriptive metadata about the collection
json.label @collection.title
json.description @collection.description

# Thumbnail image
rep = @collection.effective_file_representation
if rep
  if rep.type == Representation::Type::MEDUSA_FILE && rep.file
    thumb_url = ImageServer.file_image_v2_url(file: rep.file,
                                              size: ItemsHelper::DEFAULT_THUMBNAIL_SIZE)
  elsif rep.type == Representation::Type::LOCAL_FILE && rep.key
    thumb_url = ImageServer.s3_image_v2_url(bucket: KumquatS3Client::BUCKET,
                                            key:    rep.key,
                                            size:   ItemsHelper::DEFAULT_THUMBNAIL_SIZE)
  end
  json.thumbnail do
    json.set! '@id', thumb_url
    json.service do
      json.set! '@context', 'http://iiif.io/api/image/2/context.json'
      json.set! '@id', thumb_url
      json.profile 'http://iiif.io/api/image/2/level2.json'
    end
  end
end

json.rendering({ '@id': collection_url(@collection), format: 'text/html' })
json.seeAlso [ { '@id': collection_url(@collection, format: :json),
                 format: 'application/json' },
               { '@id': collection_url(@collection, format: :atom),
                 format: 'application/atom+xml' } ]

json.viewingHint 'individuals'

# Rights information
license = @collection.rightsstatements_org_statement&.info_uri
json.license license if license.present?
ers = @collection.rights_statement
json.attribution ers if ers.present?

json.members(@collection.items.map do |item| # top-level items only
  {
      '@id': item_iiif_manifest_url(item),
      '@type': 'sc:Manifest',
      label: item.title
  }
end)
