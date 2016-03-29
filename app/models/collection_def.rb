##
# Database representation of a collection.
#
class CollectionDef < ActiveRecord::Base

  belongs_to :metadata_profile
  belongs_to :theme
  has_many :element_defs, inverse_of: :collection_def

  validates :metadata_profile, presence: true
  validates :repository_id, presence: true

  def medusa_data_file_group
    unless @data_file_group
      @data_file_group = nil
      if self.medusa_data_file_group_id
        @data_file_group = MedusaFileGroup.new
        @data_file_group.id = self.medusa_data_file_group_id
      end
    end
    @data_file_group
  end

  def medusa_metadata_file_group
    unless @metadata_file_group
      @metadata_file_group = nil
      if self.medusa_metadata_file_group_id
        @metadata_file_group = MedusaFileGroup.new
        @metadata_file_group.id = self.medusa_metadata_file_group_id
      end
    end
    @metadata_file_group
  end

  def to_param
    self.repository_id
  end

end
