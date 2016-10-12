# Metadata about this canvas
json.set! '@context', 'http://iiif.io/api/presentation/2/context.json'
json.set! '@id', item_iiif_canvas_url(@item, @page.repository_id)
json.set! '@type', 'sc:Canvas'
json.label @page.title
json.height @page.access_master_bytestream&.height
json.width @page.access_master_bytestream&.width

if @page.is_image?
  json.images do
    json.set! '@type', 'oa:Annotation'
    json.set! '@id', item_iiif_annotation_url(@page, @page.repository_id)
  end
end