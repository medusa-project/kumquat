##
# Base controller for all controllers related to the public website.
#
class WebsiteController < ApplicationController

  def setup
    super
    @storage_offline =
        (Option::string(Option::Keys::SERVER_STATUS) == 'storage_offline')
  end

  protected

  ##
  # Raises an error if the request is not authorized to access the given model.
  #
  # @param model [Object]
  # @return [Boolean]
  #
  def authorize(model)
    if model&.respond_to?(:authorized_by_any_roles?) # AuthorizableByRole method
      unless model.authorized_by_any_roles?(request_roles)
        msg = sprintf('Authorization for %s %s denied for roles: %s',
                      model.class.to_s,
                      model.respond_to?(:repository_id) ? model.repository_id : model.id,
                      request_roles.to_a.join(', '))
        raise AuthorizationError, msg
      end
    end
  end

  ##
  # @param model [Object]
  # @return [Boolean]
  #
  def authorized?(model)
    authorized = true
    if model&.respond_to?(:authorized_by_any_roles?) # AuthorizableByRole method
      authorized = model.authorized_by_any_roles?(request_roles)
    end
    authorized
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
