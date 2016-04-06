##
# https://github.com/rails-api/active_model_serializers
#
class ItemSerializer < ActiveModel::Serializer
  root false
  attributes :id, :bytestreams, :metadata, :page_number, :subpage_number,
             :subclass, :full_text, :date, :created, :last_indexed,
             :last_modified, :parent_url

  # TODO: parent URL, collection URL, representative item URL
=begin
  def parent_url
    object.parent ? object.parent.url : nil
  end
=end
end
