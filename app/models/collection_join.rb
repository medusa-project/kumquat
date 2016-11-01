class CollectionJoin < ActiveRecord::Base

  # We use repository IDs for joins because the collection hierarchy is defined
  # externally to the DLS. This makes it easier to carry over to the DLS.
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