iiif_images_for(@item, @annotation_name).each do |k, v|
  json.set! k, v
end