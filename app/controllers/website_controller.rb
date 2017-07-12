##
# Base controller for all controllers related to the public website.
#
class WebsiteController < ApplicationController

  def setup
    super

    # Data for the nav bar search. If there is a single collection in the
    # current context, use the fields of its metadata profile. Otherwise, use
    # the fields of the default metadata profile.
    collection = self.collection
    if collection
      profile_elements = collection.effective_metadata_profile.elements
    else
      profile_elements = MetadataProfile.where(default: true).limit(1).first.
          elements
    end

    finder = CollectionFinder.new.
        client_hostname(request.host).
        client_ip(request.remote_ip).
        client_user(current_user).
        include_unpublished_in_medusa(false).
        include_unpublished_in_dls(false).
        order(Collection::SolrFields::TITLE).
        limit(99999)
    @searchable_collections = finder.to_a

    @elements_for_select = profile_elements.where(searchable: true).
        order(:label).map{ |ed| [ ed.label, ed.solr_multi_valued_field ] }
    @elements_for_select.unshift([ 'Any Field', Item::SolrFields::SEARCH_ALL ])

    @storage_offline =
        (Option::string(Option::Keys::SERVER_STATUS) == 'storage_offline')
  end

  protected

  ##
  # Renders an error template if the request is not authorized to access the
  # given model.
  #
  # @param model [Object]
  # @return [Boolean]
  #
  def authorize(model)
    if model&.respond_to?(:authorized_by_any_roles?) # AuthorizableByRole method
      unless model.authorized_by_any_roles?(request_roles)
        render 'errors/error', status: :forbidden, locals: {
            status_code: 403,
            status_message: 'Forbidden',
            message: "You are not authorized to access this "\
              "#{model.class.to_s.downcase}."
        }
        return false
      end
    end
    if model&.respond_to?(:published)
      unless model.published
        render 'errors/error', status: :forbidden, locals: {
            status_code: 403,
            status_message: 'Forbidden',
            message: "This #{model.class.to_s.downcase} is not published."
        }
        return false
      end
    end
    true
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
    if model&.respond_to?(:published)
      authorized = model.published
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
