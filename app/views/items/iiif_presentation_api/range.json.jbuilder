iiif_range_for(@item, @subitem).each do |k, v|
  json.set! k, v
end