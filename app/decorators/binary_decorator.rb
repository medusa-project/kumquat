##
# Assists in creating an optimized JSON serialization.
#
class BinaryDecorator < Draper::Decorator
  delegate_all
  include Draper::LazyHelpers

  # Define presentation-specific methods here. Helpers are accessed through
  # `helpers` (aka `h`). You can override attributes, for example:
  #
  #   def created_at
  #     helpers.content_tag :span, class: 'time' do
  #       object.created_at.strftime("%a %m/%d/%y")
  #     end
  #   end

  def serializable_hash(opts)
    struct = object.serializable_hash(opts)
    if object.binary_type == Binary::Type::PRESERVATION_MASTER
      struct[:url] = item_preservation_master_binary_url(object.item)
    else
      struct[:url] = item_access_master_binary_url(object.item)
    end
    struct
  end

end
