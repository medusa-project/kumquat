##
# https://github.com/rails-api/active_model_serializers
#
class CollectionSerializer < ActiveModel::Serializer
  root false
  attributes :repository_id, :title, :access_url, :description,
             :description_html
end
