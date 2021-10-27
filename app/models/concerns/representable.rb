##
# Module included by models that can be represented by other objects.
#
module Representable

  ##
  # @return [Collection,Item,Medusa::File]
  #
  def effective_representative_object
    raise 'Implementations must override effective_representative_object()'
  end

  ##
  # Shortcut to accessing the [Medusa::File] associated (directly or
  # indirectly) with the instance returned from
  # {effective_representative_object}.
  #
  # @return [Medusa::File]
  #
  def effective_representative_image_file
    raise 'Implementations must override effective_representative_image_file()'
  end

end
