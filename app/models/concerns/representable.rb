##
# Module included by models that can be represented by other objects.
#
module Representable

  ##
  # @return [Representation] Instance of type
  #                          {Representation::Type::LOCAL_FILE} or
  #                          {Representation::Type::MEDUSA_FILE}.
  #
  def effective_file_representation
    raise "Implementations must override #{__method__}"
  end

  ##
  # @return [Representation]
  #
  def effective_representation
    raise "Implementations must override #{__method__}()"
  end

end
