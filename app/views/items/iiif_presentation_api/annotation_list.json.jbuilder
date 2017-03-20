iiif_annotation_list_for(@item, @annotation_list_name).each do |k, v|
  json.set! k, v
end