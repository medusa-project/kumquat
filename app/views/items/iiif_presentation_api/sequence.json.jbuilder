# Metadata about this sequence
json.set! '@context', 'http://iiif.io/api/presentation/2/context.json'
json.set! '@id', item_iiif_sequence_url(@item, @sequence_name)
json.set! '@type', 'sc:Sequence'
json.label 'Page Order'

json.viewingDirection 'left-to-right'
json.viewingHint 'paged'

if @start_canvas_item
  json.startCanvas item_iiif_canvas_url(@start_canvas_item,
                                        @start_canvas_item.repository_id)
end

json.canvases(@item.pages.map do |page|
  {
      '@id': item_iiif_canvas_url(page, page.repository_id),
      '@type': 'sc:Canvas',
      'label': "Page #{page.page_number}"
  }
end)
