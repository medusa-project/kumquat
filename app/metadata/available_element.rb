##
# An element available for use in a metadata profile, and thus ascribable to
# an item.
#
class AvailableElement < ActiveRecord::Base

  validates :name, presence: true, format: { with: /\A[-a-zA-Z0-9]+\Z/ },
            uniqueness: { case_sensitive: false }

  before_update :restrict_name_changes
  before_destroy :restrict_delete_of_used_elements



  ##
  # @return [Integer]
  #
  def num_usages_by_items
    Element.where(name: self.name).count
  end

  ##
  # @return [Integer]
  #
  def num_usages_by_metadata_profiles
    ElementDef.where(name: self.name).count
  end
  # Disallows instances with any uses from being destroyed.
  #
  def restrict_delete_of_used_elements
    self.num_usages_by_items == 0 and self.num_usages_by_metadata_profiles == 0
  end

  ##
  # Disallows the name from being changed.
  #
  def restrict_name_changes
    self.name_was == self.name
  end

end
