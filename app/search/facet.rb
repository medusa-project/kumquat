class Facet

  # @!attribute name Facet field
  #   @return [String]
  attr_accessor :field

  # @!attribute name Facet name a.k.a. label
  #   @return [String]
  attr_accessor :name

  # @!attribute order
  #   @return [Integer] One of the {MetadataProfileElement::FacetOrder}
  #                     constant values.
  attr_accessor :order

  # @!attribute terms
  #   @return [Array<FacetTerm>]
  attr_reader :terms

  def initialize
    @terms = []
  end

end
