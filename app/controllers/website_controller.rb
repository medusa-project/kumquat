##
# Base controller for all controllers related to the public website.
#
class WebsiteController < ApplicationController

  before_action :prepend_view_paths

  def setup
    super

    @num_items = Item.count

    @audio_items = Item.where("#{Solr::Fields::ACCESS_MASTER_MEDIA_TYPE}:audio/* "\
    "OR #{Solr::Fields::PRESERVATION_MASTER_MEDIA_TYPE}:audio/*").limit(1)
    @document_items = Item.where("#{Solr::Fields::ACCESS_MASTER_MEDIA_TYPE}:application/pdf "\
    "OR #{Solr::Fields::PRESERVATION_MASTER_MEDIA_TYPE}:application/pdf").limit(1)
    @image_items = Item.where("#{Solr::Fields::ACCESS_MASTER_MEDIA_TYPE}:image/* "\
    "OR #{Solr::Fields::PRESERVATION_MASTER_MEDIA_TYPE}:image/*").limit(1)
    @video_items = Item.where("#{Solr::Fields::ACCESS_MASTER_MEDIA_TYPE}:video/* "\
        "OR #{Solr::Fields::PRESERVATION_MASTER_MEDIA_TYPE}:video/*").limit(1)

    # data for the nav bar search
    @collections = Collection.all
    @predicates_for_select = [].
        map{ |p| [ p.label, p.solr_field ] }.uniq
    @predicates_for_select.unshift([ 'Any Field', Solr::Fields::SEARCH_ALL ])

  end

  private

  ##
  # Allow view templates to be overridden by adding custom templates to
  # /local/themes/[theme name]/views.
  #
  def prepend_view_paths
    unless @skip_after_actions
      id = 'default'
      if controller_name == 'collections'
        id = params[:id]
      elsif controller_name == 'items'
        if params[:collection_id]
          id = params[:collection_id]
        else
          item = Item.find(params[:id])
          id = item.collection.id
        end
      end
      collection = CollectionDef.find_by_repository_id(id)
      theme = collection ? collection.theme : Theme.default
      pathname = theme ? File.join(Rails.root, theme.pathname, 'views') : nil
      prepend_view_path(pathname) if pathname
    end
  end

end
