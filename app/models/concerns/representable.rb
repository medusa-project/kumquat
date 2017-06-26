##
# Module included by models that can be represented by other models.
#
module Representable

  ##
  # @return [Object]
  #
  def effective_representative_entity
    raise 'Implementations must override effective_representative_entity()'
  end

end
