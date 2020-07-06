##
# Base controller for all controllers related to the public website.
#
class WebsiteController < ApplicationController

  MAX_RESULT_WINDOW = 100
  MIN_RESULT_WINDOW = 10

  protected

  ##
  # Raises an error if the request is not authorized to access the given model.
  #
  # @param model [Object]
  # @return [Boolean]
  #
  def authorize(model)
    return unless model
    authorize_host_group(model)
    authorize_restricted(model)
  end

  def authorize_host_group(model)
    if model.respond_to?(:authorized_by_any_host_groups?) # AuthorizableByHost method
      unless model.authorized_by_any_host_groups?(client_host_groups)
        msg = sprintf('Authorization for %s %s denied for host groups: [%s]',
                      model.class.to_s,
                      model.respond_to?(:repository_id) ? model.repository_id : model.id,
                      client_host_groups.to_a.join(', '))
        raise AuthorizationError, msg
      end
    end
  end

  def authorize_restricted(model)
    if model.kind_of?(Item) && model.restricted # DLD-337
      username = current_user&.username
      raise AuthorizationError unless username.present? &&
          model.allowed_netids&.map{ |h| h[:netid] }&.include?(username)
    elsif model.kind_of?(Collection) && model.restricted
      raise AuthorizationError
    end
  end

  ##
  # @return [Collection,nil], Collection in the current context, or nil if
  #                           there is <> 1
  #
  def collection
    id = nil
    if controller_name == 'collections'
      id = params[:id]
    elsif controller_name == 'items'
      if params[:collection_id]
        id = params[:collection_id]
      elsif params[:id]
        item = Item.find_by_repository_id(params[:id])
        id = item&.collection&.repository_id
      end
    end
    if id
      return Collection.find_by_repository_id(id)
    end
    nil
  end

  def enable_cors
    headers['Access-Control-Allow-Origin'] = '*'
  end

end
