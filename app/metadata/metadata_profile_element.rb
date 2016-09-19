##
# Encapsulates an element in a metadata profile.
#
class MetadataProfileElement < ActiveRecord::Base

  belongs_to :metadata_profile, inverse_of: :elements
  has_and_belongs_to_many :vocabularies

  validates_uniqueness_of :name, scope: :metadata_profile_id

  after_save :adjust_profile_element_indexes_after_save
  after_destroy :adjust_profile_element_indexes_after_destroy

  ##
  # @return [MetadataProfileElement]
  #
  def dup
    clone = super
    clone.vocabulary_ids = self.vocabulary_ids
    clone
  end

  def solr_facet_field
    e = ItemElement.new
    e.name = self.name
    e.name == 'collection' ?
        Item::SolrFields::COLLECTION + ItemElement.solr_facet_suffix :
        e.solr_facet_field
  end

  def solr_multi_valued_field
    e = ItemElement.new
    e.name = self.name
    e.solr_multi_valued_field
  end

  def solr_single_valued_field
    e = ItemElement.new
    e.name = self.name
    e.solr_single_valued_field
  end

  def to_s
    self.name
  end

  private

  ##
  # Updates the indexes of all elements in the metadata profile to ensure that
  # they are sequential.
  #
  def adjust_profile_element_indexes_after_destroy
    ActiveRecord::Base.transaction do
      if self.metadata_profile and self.destroyed?
        self.metadata_profile.elements.order(:index).each_with_index do |element, i|
          # update_column skips callbacks, which would cause this method to be
          # called recursively.
          element.update_column(:index, i)
        end
      end
    end
  end

  ##
  # Updates the indexes of all elements in the metadata profile to ensure that
  # they are sequential.
  #
  def adjust_profile_element_indexes_after_save
    ActiveRecord::Base.transaction do
      if self.metadata_profile and self.changed.include?('index')
        # update_column skips callbacks, which would cause this method to be
        # called recursively.
        self.update_column(:index, 0) if self.index < 0
        self.metadata_profile.elements.where('id != ?', self.id).order(:index).
            each_with_index do |element, i|
          element.update_column(:index, (i >= self.index) ? i + 1 : i)
        end
      end
    end
  end

end
