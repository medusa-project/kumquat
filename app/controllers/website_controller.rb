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
      key = 'default'
      if params[:key]
        key = params[:key]
      elsif params[:repository_collection_key]
        key = params[:repository_collection_key]
      elsif params[:web_id]
        item = Item.find_by_web_id(params[:web_id])
        raise ActiveRecord::RecordNotFound unless item
        key = item.collection.key
      end

      theme = nil
      #collection = DB::Collection.find_by_key(key)
      #theme = collection.theme if collection
      theme ||= Theme.default
      pathname = nil
      pathname = File.join(Rails.root, theme.pathname, 'views') if theme
      prepend_view_path(pathname) if pathname
    end
  end

end
