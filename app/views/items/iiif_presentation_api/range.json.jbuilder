iiif_range_for(@item, @range).each do |k, v|
  json.set! k, v
end