##
# Rack application to handle streaming zip downloads of favorites.
#
# URL query parameters:
# * items: comma-delimited list of UUIDs
# * start: integer
#
class FavoritesZipDownloader < AbstractZipDownloader

  def call(env)
    super(env)

    items = []

    # We don't use ItemFinder here because we need to be able to descend item
    # trees, which ItemFinder can't do.
    ids = params[:items].split(',')
    if ids.any?
      start = params[:start].to_i
      end_ = [BATCH_SIZE - 1, ids.length - start].min
      ids = ids[start..end_]
      ids.each do |id|
        item = Item.find_by_repository_id(id)
        if item
          items << item
          items += item.items(true)
        end
      end
    end

    # Strip out unauthorized items. Presumably these would not be present in a
    # user's favorites in the first place, but let's be on the safe side.
    authorized_items = []
    items.each do |item|
      if item.authorized_by_any_roles?(roles(env['HTTP_HOST'], env['REMOTE_ADDR'])) # TODO: include user account roles
        authorized_items << item
      end
    end

    if authorized_items.any?
      send_items(authorized_items)
    else
      return [400, {}, 'No items to include in zip file.']
    end
  end

  ##
  # @param hostname [String] Client hostname
  # @param ip [String] Client IP address
  # @return [Set<Role>] Set of Roles associated with the client user, if
  #                     available, and the client hostname/IP address.
  #
  def roles(hostname, ip)
    roles = Set.new
    #roles += @client_user.roles if @client_user # TODO: fix
    roles += Role.all_matching_hostname_or_ip(hostname, ip) if hostname or ip
    roles
  end

end
