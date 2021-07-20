# Metadata about this manifest file
json.set! '@context', 'http://iiif.io/api/presentation/2/context.json'
json.set! '@id', item_iiif_manifest_url(@item)
json.set! '@type', 'sc:Manifest'

# Descriptive metadata about the object/work
json.label @item.title
json.metadata iiif_metadata_for(@item)
json.description @item.description if @item.description.present?

services = []

if @item.has_full_text?(include_children: true)
  services << iiif_search_service_description(@item)
end

# Images
thumb_url = item_image_url(item: @item,
                           size: ItemsHelper::DEFAULT_THUMBNAIL_SIZE)
if thumb_url
  json.thumbnail do
    json.set! '@id', thumb_url
    json.service do
      json.set! '@context', 'http://iiif.io/api/image/2/context.json'
      json.set! '@id', @item.effective_image_binary&.iiif_image_v2_url
      json.profile 'http://iiif.io/api/image/2/level2.json'
    end
  end

  services << {
    '@context': 'http://iiif.io/api/image/2/context.json',
    '@id':      @item.effective_image_binary&.iiif_image_v2_url,
    profile:    'http://iiif.io/api/image/2/level2.json'
  }
end

json.service services.select(&:present?)

json.logo image_url('Illinois-Logo-Reversed-Orange-RGB-100.png')
json.related({ '@id': item_url(@item), format: 'text/html' })
json.seeAlso [ { '@id': item_url(@item, format: :json), format: 'application/json' },
               { '@id': item_url(@item, format: :atom), format: 'application/atom+xml' } ]

# Presentation information
json.viewingDirection 'left-to-right'
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
json.sequences iiif_sequences_for(@item)

# List of IxIF media sequences (API extension)
# Disabled due to a potential Safari bug
# (see https://github.com/UniversalViewer/universalviewer/issues/372)
#json.mediaSequences iiif_media_sequences_for(@item)

# List of ranges
json.structures iiif_ranges_for(@item)
