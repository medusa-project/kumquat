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

    ##
    # @param params [Hash] Rails params hash
    # @return [Hash] Input hash
    #
    def added_to_params(params)
      params[:fq] = [] unless params[:fq].respond_to?(:each)
      params[:fq] = params[:fq].reject do |t|
        t.start_with?("#{self.facet.field.chomp('_facet')}:")
      end
      params[:fq] << self.facet_query
      params
    end

    ##
    # @return [String]
    #
    def facet_query
      "#{self.facet.field}:\"#{self.name}\""
    end

    ##
    # @param params [Hash] Rails params hash
    # @return [Hash] Input hash
    #
    def removed_from_params(params)
      params[:fq] = [] unless params[:fq].respond_to?(:each)
      params[:fq] = params[:fq].reject { |t| t == self.facet_query }
      params
    end

  end

  attr_accessor :field
  attr_reader :terms

  def initialize
    @terms = []
  end

end
