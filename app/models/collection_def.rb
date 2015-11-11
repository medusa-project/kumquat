##
# Database representation of a collection.
#
class CollectionDef < ActiveRecord::Base

  belongs_to :metadata_profile
  belongs_to :theme
  has_many :element_defs, inverse_of: :collection_def

  validates :metadata_profile, presence: true
  validates :repository_id, presence: true

  def to_param
    self.repository_id
  end

end
