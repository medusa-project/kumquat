iiif_canvas_for(@page, include_metadata: true).each do |k, v|
  json.set! k, v
end
