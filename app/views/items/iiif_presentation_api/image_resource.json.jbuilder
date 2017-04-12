iiif_image_resources_for(@item, @image_resource_name).each do |k, v|
  json.set! k, v
end