##
# Encapsulates a metadata element attached to a collection, with a name
# matching one of the Element names.
#
class CollectionElement < EntityElement

  belongs_to :collection, inverse_of: :elements, touch: true

  ##
  # @return [Enumerable<CollectionElement>]
  #
  def self.all_available
    Element.all.map { |e| CollectionElement.new(name: e.name) }
  end

  ##
  # @return [CollectionElement] CollectionElement with the given name, or nil
  #                             if the given name is not an available element
  #                             name.
  #
  def self.named(name)
    all_available.select{ |e| e.name == name }.first
  end

  def ==(obj)
    obj.kind_of?(CollectionElement) and obj.name == self.name and
        obj.value == self.value and obj.uri == self.uri and
        obj.vocabulary_id == self.vocabulary_id
  end

end