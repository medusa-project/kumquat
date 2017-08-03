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
    {
        id: binary.cfs_file_uuid,
        url: binary_url(object),
        master_type: object.human_readable_master_type,
        media_category: object.human_readable_media_category,
        byte_size: object.byte_size,
        width: object.width,
        height: object.height,
        created_at: binary.created_at,
        updated_at: binary.updated_at,
    }
  end

end
