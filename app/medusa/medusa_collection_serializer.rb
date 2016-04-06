##
# https://github.com/rails-api/active_model_serializers
#
class MedusaCollectionSerializer < ActiveModel::Serializer
  root false
  attributes :id, :title, :access_url, :description, :description_html,
             :last_indexed
end
