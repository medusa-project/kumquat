class Facet

  class Term

    # @!attribute count
    #   @return [Integer]
    attr_accessor :count

    # @!attribute facet
    #   @return [Facet] The facet with which the term is associated.
    attr_accessor :facet

    # @!attribute label
    #   @return [String]
    attr_accessor :label

    # @!attribute name
    #   @return [String]
    attr_accessor :name

    def initialize
      @count = 0
    end

  end

  attr_accessor :field
  attr_reader :terms

  def initialize
    @terms = []
  end

end
