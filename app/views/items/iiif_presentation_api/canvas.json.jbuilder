# Metadata about this canvas
json.set! '@context', 'http://iiif.io/api/presentation/2/context.json'
json.set! '@id', item_iiif_canvas_url(@item, @page.repository_id)
json.set! '@type', 'sc:Canvas'
json.label @page.title

min_size = IiifPresentationHelper::MIN_CANVAS_SIZE
height = @page.access_master_bytestream&.height || min_size
height *= 2 if height < min_size
width = @page.access_master_bytestream&.width || min_size
width *= 2 if width < min_size

json.height height
json.width width

if @page.is_image?
  json.images do
    json.set! '@type', 'oa:Annotation'
    json.set! '@id', item_iiif_annotation_url(@page, 'access')
  end
end