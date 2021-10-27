##
# Module included by models that can be represented by other objects.
#
module Representable

  ##
  # @return [Medusa::File,Binary,Collection,Item]
  #
  def effective_representative_entity
    raise 'Implementations must override effective_representative_entity()'
  end

  ##
  # @return [Medusa::File]
  #
  def effective_representative_image_file
    raise 'Implementations must override effective_representative_image_file()'
  end

end
