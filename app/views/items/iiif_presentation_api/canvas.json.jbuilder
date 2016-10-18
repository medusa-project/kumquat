iiif_canvas_for(@page).each do |k, v|
  json.set! k, v
end
