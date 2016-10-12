# Metadata about this sequence
json.set! '@context', 'http://iiif.io/api/presentation/2/context.json'
json.set! '@id', item_iiif_sequence_url(@item, @sequence_name)
json.set! '@type', 'sc:Sequence'
json.label 'Page Order'

json.viewingDirection 'left-to-right'
json.viewingHint 'paged'
json.startCanvas item_iiif_canvas_url(@item, 'page1')

json.canvases iiif_canvases(@item)
