##
# https://github.com/rails-api/active_model_serializers
#
class ItemSerializer < ActiveModel::Serializer
  root false
  attributes :id, :bytestreams, :elements, :page_number, :subpage_number,
             :subclass, :full_text, :last_indexed,
             :collection, :representative_item, :parent_item

  def collection
    collection_url(object.collection, only_path: true)
  end

  def parent_item
    object.parent ? item_url(object.parent, only_path: true) : nil
  end

  def representative_item
    item_url(object.representative_item, only_path: true)
  end

end
