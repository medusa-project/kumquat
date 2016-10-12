json.set! '@context', 'http://iiif.io/api/presentation/2/context.json'
json.set! '@id', collection_iiif_presentation_url(@collection)
json.set! '@type', 'sc:Collection'
json.label @collection.title
json.description @collection.description
json.attribution @collection.rights_statement

json.manifests iiif_manifests_for(@collection)