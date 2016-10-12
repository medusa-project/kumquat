json.set! '@context', 'http://iiif.io/api/presentation/2/context.json'
json.set! '@id', item_iiif_annotation_url(@item, @annotation_name)
json.set! '@type', 'oa:Annotation'
json.motivation 'sc:painting'

json.resource do
  json.set! '@id', iiif_image_url(@item, 1000)
  json.set! '@type', 'dctypes:Image'
  json.set! '@format', @bytestream&.media_type
  json.service do
    json.set! '@context', 'http://iiif.io/api/image/2/context.json'
    json.set! '@id', iiif_bytestream_url(@bytestream)
    json.profile 'http://iiif.io/api/image/2/profiles/level2.json'
  end
  json.height @bytestream&.height
  json.width @bytestream&.width
end

json.on item_iiif_canvas_url(@item, @item.repository_id)
