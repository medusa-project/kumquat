##
# Module included by models that have a has_many `elements` relationship to
# EntityElement subclasses.
#
module Describable

  ##
  # @return [Element]
  #
  def description
    self.element(:description)&.value
  end

  ##
  # Convenience method that retrieves one element with the given name from the
  # instance's `elements` relationship.
  #
  # @param name [String, Symbol] Element name
  # @return [EntityElement]
  #
  def element(name)
    self.elements.where(name: name).limit(1).first
  end

  ##
  # @return [Element]
  #
  def subtitle
    self.element(:alternativeTitle)&.value
  end

  ##
  # @return [EntityElement]
  #
  def title
    t = self.element(:title)&.value
    t.present? ? t : self.repository_id
  end

end
