# Metadata about this sequence
json.set! '@id', item_iiif_media_sequence_url(@item, @media_sequence_name)
json.set! '@type', 'ixif:MediaSequence'
json.label 'XSequence 0'

json.elements [
    '@id': item_access_master_binary_url(@item),
    '@type': 'foaf:Document',
    format: @item.access_master_binary.media_type,
    label: @item.title,
    metadata: [],
    thumbnail: thumbnail_url(@item)
]
