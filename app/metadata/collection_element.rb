##
# Encapsulates a metadata element attached to a collection, with a name
# matching one of the Element names.
#
class CollectionElement < EntityElement

  belongs_to :collection, inverse_of: :elements, touch: true

  # N.B.: This is needed to ward off the following
  # ActiveRecord::SubclassNotFound error: "Invalid single-table inheritance
  # type: CollectionElement is not a subclass of CollectionElement"
  # which cropped up in the development environment after including the
  # elasticsearch-model gem 5.0.1.
  # See: https://github.com/galetahub/ckeditor/issues/739#issuecomment-303773864
  # TODO: see if it's safe to get rid of this now that we are no longer using elasticsearch-model
  self.inheritance_column = nil

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