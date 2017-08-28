# Metadata about this file
json.set! '@context', 'http://iiif.io/api/presentation/2/context.json'
json.set! '@id', collection_iiif_presentation_url(@collection)
json.set! '@type', 'sc:Collection'

# Descriptive metadata about the collection
json.label @collection.title
json.description @collection.description

# Thumbnail image
bs = @collection.effective_representative_image_binary
if bs
  thumb_url = thumbnail_url(bs)
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
