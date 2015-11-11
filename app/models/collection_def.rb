##
# Database representation of a collection.
#
class CollectionDef < ActiveRecord::Base

  self.table_name = 'collections'

  belongs_to :metadata_profile
  belongs_to :theme
  has_many :element_defs, inverse_of: :collection_def

  validates :metadata_profile, presence: true
  validates :repository_id, allow_blank: false

  def to_param
    self.repository_id
  end

end
