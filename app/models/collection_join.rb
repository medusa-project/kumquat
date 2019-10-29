##
# Parent-child relationship between two collections.
#
# AFAIK we need only a tree structure and not multiple inheritance, but this
# is how the relationships are defined in the Collection Registry, so we carry
# it over.
#
class CollectionJoin < ApplicationRecord

  # We use repository IDs for joins because the collection hierarchy is defined
  # externally to the application.
  belongs_to :parent_collection, class_name: 'Collection',
             primary_key: :repository_id, foreign_key: :parent_repository_id
  belongs_to :child_collection, class_name: 'Collection',
             primary_key: :repository_id, foreign_key: :child_repository_id

  validates_presence_of :parent_repository_id
  validates_presence_of :child_repository_id

  validates_each :child_repository_id do |record, attr, value|
    record.errors.add attr, 'Collection cannot be a child collection of itself' if
        value == record.parent_repository_id
  end

end
