##
# Database representation of a metadata element definition. Primarily used in
# collection metadata profiles.
#
class ElementDef < ActiveRecord::Base

  belongs_to :metadata_profile, inverse_of: :element_defs

  after_save :adjust_profile_element_indexes_after_save
  after_destroy :adjust_profile_element_indexes_after_destroy

  ##
  # Updates the indexes of all elements in the same metadata profile to ensure
  # that they are non-repeating and properly gapped.
  #
  def adjust_profile_element_indexes_after_destroy
    if self.metadata_profile and self.destroyed?
      self.metadata_profile.element_defs.order(:index).each_with_index do |element, i|
        element.update_column(:index, i) # update_column skips callbacks
      end
    end
  end

  ##
  # Updates the indexes of all elements in the same metadata profile to ensure
  # that they are non-repeating and properly gapped.
  #
  def adjust_profile_element_indexes_after_save
    if self.metadata_profile and self.changed.include?('index')
      self.metadata_profile.element_defs.where('id != ?', self.id).order(:index).
          each_with_index do |element, i|
        # update_column skips callbacks
        element.update_column(:index, (i >= self.index) ? i + 1 : i)
      end
    end
  end

  def solr_facet_name
    e = Element.new
    e.name = self.name
    e.name == 'collection' ?
        "collection_si#{Element.solr_facet_suffix}" : e.solr_facet_name
  end

  def solr_name
    e = Element.new
    e.name = self.name
    e.solr_name
  end

  def solr_sortable_name
    e = Element.new
    e.name = self.name
    e.solr_sortable_name
  end

  def to_s
    self.name
  end

end
