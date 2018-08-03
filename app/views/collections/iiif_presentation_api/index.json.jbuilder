json.set! '@context', 'http://iiif.io/api/presentation/2/context.json'
json.set! '@id', collections_iiif_presentation_list_url
json.set! '@type', 'sc:Collection'

json.label Option::string(Option::Keys::WEBSITE_NAME)
json.description strip_tags(Option::string(Option::Keys::WEBSITE_INTRO_TEXT))

json.logo image_url('Illinois-Logo-Reversed-Orange-RGB-100.png')

json.collections iiif_collection_list_for(@collections)
