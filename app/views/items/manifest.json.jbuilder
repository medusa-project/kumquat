# Metadata about this manifest file
json.set! '@context', 'http://iiif.io/api/presentation/2/context.json'
json.set! '@id', item_iiif_manifest_url(@item)
json.set! '@type', 'sc:Manifest'

# Descriptive metadata about the object/work
json.label @item.title
json.metadata iiif_metadata_for(@item)
json.description @item.description
json.thumbnail do
  json.set! '@id', thumbnail_url(@item)
  json.service do
    json.set! '@context', 'http://iiif.io/api/image/2/context.json'
    json.set! '@id', @item.iiif_url
    json.profile 'http://iiif.io/api/image/2/level2.json'
  end
end

# Presentation information
json.viewingDirection 'right-to-left'
if @item.pages.count > 0
  json.viewingHint 'paged'
else
  json.viewingHint 'individuals'
end
json.navDate @item.date.utc.iso8601 if @item.date

# Rights information
json.license @item.effective_rightsstatements_org_statement.info_uri
json.attribution @item.effective_rights_statement

# List of sequences
if @item.pages.count > 0
  json.sequences do
    json.set! '@id', item_iiif_sequence_url(@item)
    json.set! '@type', 'sc:Sequence'
    json.label 'Page Order'
  end
end