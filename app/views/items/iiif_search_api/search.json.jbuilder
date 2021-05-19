json.set! '@context', 'http://iiif.io/api/presentation/2/context.json'
json.set! '@id', request.url
json.set! '@type', 'sc:AnnotationList'

resources = []
@items.each do |item|
  binary = item.full_text_binary
  coords = binary.word_coordinates(params[:q])
  coords.each do |rect|
    resources << {
      '@id': item_iiif_annotation_list_url(item, IiifPresentationHelper::DEFAULT_ANNOTATION_LIST_NAME),
      '@type': 'oa:Annotation',
      motivation: 'sc:painting',
      resource: {
        '@type': 'cnt:ContentAsText',
        chars: binary.full_text
      },
      on: item_iiif_canvas_url(item, IiifPresentationHelper::DEFAULT_CANVAS_NAME,
                               anchor: "xywh=#{rect[:x]},#{rect[:y]},#{rect[:width]},#{rect[:height]}")
    }
  end
end

json.resources(resources)
