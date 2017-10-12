class FacetTerm

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
  # @param params [ActionController::Parameters]
  # @return [ActionController::Parameters] Input params
  #
  def added_to_params(params)
    params[:fq] = [] unless params[:fq].respond_to?(:each)
    params[:fq] << self.query
    params
  end

  ##
  # @return [String]
  #
  def query
    "#{self.facet.field}:#{self.name}"
  end

  ##
  # @param params [ActionController::Parameters]
  # @return [ActionController::Parameters] Input params
  #
  def removed_from_params(params)
    if params[:fq].respond_to?(:each)
      params[:fq] = params[:fq].reject{ |t| t == self.query }
    end
    params
  end

end