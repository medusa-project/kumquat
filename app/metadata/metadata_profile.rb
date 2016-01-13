class MetadataProfile < ActiveRecord::Base

  has_many :collection_defs, inverse_of: :metadata_profile,
           dependent: :restrict_with_error
  has_many :element_defs, -> { order(:index) }, inverse_of: :metadata_profile,
           dependent: :destroy

  validates :name, presence: true, length: { minimum: 2 },
            uniqueness: { case_sensitive: false }

  after_save :ensure_default_uniqueness

  ##
  # Overrides parent to intelligently clone a metadata profile including all
  # of its elements.
  #
  # @return [MetadataProfile]
  #
  def dup
    clone = super
    clone.default = false
    self.element_defs.each { |t| clone.element_defs << t.dup }
    clone
  end

  def solr_facet_fields
    self.element_defs.select{ |d| d.facetable }.map{ |d| d.solr_facet_name }
  end

  private

  ##
  # Makes all other instances "not default" if the instance is the default.
  #
  def ensure_default_uniqueness
    if self.default
      self.class.all.where('id != ?', self.id).each do |instance|
        instance.default = false
        instance.save!
      end
    end
  end

end
