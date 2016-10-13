# Metadata about this manifest file
json.set! '@context', 'http://iiif.io/api/presentation/2/context.json'
json.set! '@id', item_iiif_manifest_url(@item)
json.set! '@type', 'sc:Manifest'

# Descriptive metadata about the object/work
json.label @item.title
json.metadata iiif_metadata_for(@item)
json.description @item.description

# Images
thumb_url = thumbnail_url(@item)
if thumb_url
  json.thumbnail do
    json.set! '@id', thumb_url
    json.service do
      json.set! '@context', 'http://iiif.io/api/image/2/context.json'
      json.set! '@id', @item.iiif_url
      json.profile 'http://iiif.io/api/image/2/level2.json'
    end
  end

  json.service do
    json.set! '@context', 'http://iiif.io/api/image/2/context.json'
    json.set! '@id', @item.iiif_url
    json.profile 'http://iiif.io/api/image/2/level2.json'
  end
end

json.rendering({ '@id': item_url(@item), format: 'text/html' })
json.seeAlso [ { '@id': item_url(@item, format: :json), format: 'application/json' },
               { '@id': item_url(@item, format: :atom), format: 'application/atom+xml' } ]

# Presentation information
json.viewingDirection 'right-to-left'
if @item.pages.count > 0
  json.viewingHint 'paged'
else
  json.viewingHint 'individuals'
end
json.navDate @item.date.utc.iso8601 if @item.date

# Rights information
license = @item.effective_rightsstatements_org_statement&.info_uri
json.license license if license.present?
ers = @item.effective_rights_statement
json.attribution ers if ers.present?

if @item.parent
  json.within({ '@id': item_iiif_manifest_url(@item.parent),
                format: 'application/json' })
else
  json.within({ '@id': collection_iiif_presentation_url(@item.collection),
                format: 'application/json' })
end

# List of sequences
if @item.pages.count > 0
  json.sequences do
    json.set! '@id', item_iiif_sequence_url(@item, :page)
    json.set! '@type', 'sc:Sequence'
    json.label 'Pages Order'
  end
elsif @item.items.count > 0
  json.sequences do
    json.set! '@id', item_iiif_sequence_url(@item, :item)
    json.set! '@type', 'sc:Sequence'
    json.label 'Sub-Items'
  end
end
