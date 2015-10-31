##
# Array-like Enumerable.
#
class ResultSet

  include Enumerable

  # @!attribute facet_fields
  #   @return [Array] Array of `Facet::Field`s, populated by `Relation.load`.
  attr_accessor :facet_fields

  # @!attribute total_length
  #   @return [Integer]
  attr_accessor :total_length

  def initialize
    @array = []
    @total_length = 0
  end

  def each(&block)
    @array.each{ |member| block.call(member) }
  end

  def method_missing(name, *args, &block)
    @array.send(name, *args, &block)
  end

  def respond_to_missing?(method_name, include_private = true)
    @array.respond_to?(method_name, include_private)
  end

end
