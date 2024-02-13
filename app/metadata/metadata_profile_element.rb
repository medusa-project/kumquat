##
# Encapsulates an element in a [MetadataProfile].
#
# # Attributes
#
# * `created_at`          Managed by ActiveRecord.
# * `data_type`           One of the {MetadataProfileElement::DataType}
#                         constant values.
# * `dc_map`              Name of a Dublin Core element (unqualified) to which
#                         the element can be mapped.
# * `dcterms_map`         Name of a Dublin Core term to which the element can
#                         be mapped.
# * `facet_order`         One of the {MetadataProfileElement::FacetOrder}
#                         constant values.
# * `facetable`           Whether the element is used to provide facets in
#                         results views.
# * `index`               Zero-based position within the owning
#                         {MetadataProfile}.
# * `indexed`             Whether the element is added to
#                         {Item}/{Collection}/etc. indexed documents.
# * `label`               Element label. Often overrides `name` for end-user
#                         display.
# * `metadata_profile_id` Metadata profile ID. Foreign key.
# * `name`                Element name.
# * `searchable`          Whether users can search on the element.
# * `sortable`            Whether results can be sorted on the element.
# * `updated_at`          Managed by ActiveRecord.
# * `visible`             Whether the element is visible to users.
#
class MetadataProfileElement < ApplicationRecord

  ##
  # Allowed data types for the {data_type} attribute.
  #
  class DataType
    SINGLE_LINE_STRING = 0
    MULTI_LINE_STRING  = 1

    ##
    # @return [Enumerable<Integer>] Integer values of all constant values.
    #
    def self.all
      self.constants.map{ |c| self.const_get(c) }
    end
  end

  ##
  # Order of the terms appearing in an element's facet.
  #
  class FacetOrder
    FREQUENCY    = 0
    ALPHANUMERIC = 1

    ##
    # @return [Enumerable<Integer>] Integer values of all constant values.
    #
    def self.all
      self.constants.map{ |c| self.const_get(c) }
    end

    ##
    # @param data_type [Integer] One of the constant values.
    # @return                    Human-readable facet order.
    #
    def self.to_s(facet_order)
      case facet_order
      when ALPHANUMERIC
        'Alphanumeric'
      when FREQUENCY
        'Frequency'
      else
        ''
      end
    end
  end


  belongs_to :metadata_profile, inverse_of: :elements
  has_and_belongs_to_many :vocabularies

  validates :data_type, inclusion: { in: DataType.all }
  validates :facet_order, inclusion: { in: FacetOrder.all }, allow_blank: true
  validates :index, numericality: { only_integer: true,
                                    greater_than_or_equal_to: 0 },
            allow_blank: false
  validates_uniqueness_of :name, scope: :metadata_profile_id

  validate :validate_indexed_title
  validate :validate_vocabularies

  after_create :adjust_profile_element_indexes_after_create
  before_update :adjust_profile_element_indexes_before_update
  after_destroy :adjust_profile_element_indexes_after_destroy

  ##
  # @return [Boolean]
  #
  def controlled?
    !(self.vocabularies.empty? || (self.vocabularies.length == 1 &&
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

  ##
  # @return [String]
  #
  def human_readable_data_type
    case self.data_type
      when DataType::MULTI_LINE_STRING
        'Multi-Line String'
      else
        'Single-Line String'
    end
  end

  ##
  # @return [String]
  #
  def indexed_field
    ItemElement.new(name: self.name).indexed_field
  end

  ##
  # @return [String]
  #
  def indexed_keyword_field
    ItemElement.new(name: self.name).indexed_keyword_field
  end

  ##
  # @return [String]
  #
  def indexed_sort_field
    ItemElement.new(name: self.name).indexed_sort_field
  end

  def to_s
    self.name
  end


  private

  ##
  # Updates the indexes of all elements in the owning {MetadataProfile} to
  # ensure that they are sequential.
  #
  def adjust_profile_element_indexes_after_create
    if self.metadata_profile
      transaction do
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
  # Updates the indexes of all elements in the owning {MetadataProfile} to
  # ensure that they are sequential.
  #
  def adjust_profile_element_indexes_before_update
    if self.metadata_profile and self.index_changed?
      min       = [self.index_was, self.index].min
      max       = [self.index_was, self.index].max
      increased = (self.index_was < self.index)

      transaction do
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

  ##
  # Updates the indexes of all elements in the owning {MetadataProfile} to
  # ensure that they are sequential and zero-based.
  #
  def adjust_profile_element_indexes_after_destroy
    if self.metadata_profile && self.destroyed?
      transaction do
        self.metadata_profile.elements.order(:index).each_with_index do |element, index|
          # update_column skips callbacks, which would cause this method to be
          # called recursively.
          element.update_column(:index, index) if element.index != index
        end
      end
    end
  end

  ##
  # Ensures that the `title` element is always indexed.
  #
  def validate_indexed_title
    if self.name == "title" && !self.indexed
      errors.add(:indexed, "must be enabled on the title element")
    end
  end

  def validate_vocabularies
    if self.vocabularies.empty?
      errors.add(:vocabularies, 'must have at least one vocabulary assigned')
    end
  end

end
