##
# Encapsulates an element in a metadata profile.
#
class MetadataProfileElement < ApplicationRecord

  belongs_to :metadata_profile, inverse_of: :elements
  has_and_belongs_to_many :vocabularies

  validates :index, numericality: { only_integer: true,
                                    greater_than_or_equal_to: 0 },
            allow_blank: false
  validates_uniqueness_of :name, scope: :metadata_profile_id

  after_create :adjust_profile_element_indexes_after_create
  after_update :adjust_profile_element_indexes_after_update
  after_destroy :adjust_profile_element_indexes_after_destroy

  ##
  # @return [Boolean]
  #
  def controlled?
    !(self.vocabularies.empty? or (self.vocabularies.length == 1 and
        self.vocabularies.first == Vocabulary.uncontrolled))
  end

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
  # Updates the indexes of all elements in the owning metadata profile to
  # ensure that they are sequential.
  #
  def adjust_profile_element_indexes_after_create
    if self.metadata_profile
      ActiveRecord::Base.transaction do
        self.metadata_profile.elements.
            where('id != ? AND index >= ?', self.id, self.index).each do |e|
          # update_column skips callbacks, which would cause this method to
          # be called recursively.
          e.update_column(:index, e.index + 1)
        end
      end
    end
  end

  ##
  # Updates the indexes of all elements in the owning metadata profile to
  # ensure that they are sequential and zero-based.
  #
  def adjust_profile_element_indexes_after_destroy
    if self.metadata_profile and self.destroyed?
      ActiveRecord::Base.transaction do
        self.metadata_profile.elements.order(:index).each_with_index do |element, index|
          # update_column skips callbacks, which would cause this method to be
          # called recursively.
          element.update_column(:index, index) if element.index != index
        end
      end
    end
  end

  ##
  # Updates the indexes of all elements in the owning metadata profile to
  # ensure that they are sequential.
  #
  def adjust_profile_element_indexes_after_update
    if self.metadata_profile and self.index_changed?
      min = [self.index_was, self.index].min
      max = [self.index_was, self.index].max
      increased = (self.index_was < self.index)

      ActiveRecord::Base.transaction do
        self.metadata_profile.elements.
            where('id != ? AND index >= ? AND index <= ?', self.id, min, max).each do |e|
          if increased # shift the range down
            # update_column skips callbacks, which would cause this method to
            # be called recursively.
            e.update_column(:index, e.index - 1)
          else # shift it up
            e.update_column(:index, e.index + 1)
          end
        end
      end
    end
  end

end
