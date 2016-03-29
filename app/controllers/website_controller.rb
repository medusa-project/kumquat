##
# Base controller for all controllers related to the public website.
#
class WebsiteController < ApplicationController

  before_action :prepend_view_paths

  def setup
    super

    @num_items = Item.where(Solr::Fields::PARENT_ITEM => :null).count

    @audio_items = Item.where("#{Solr::Fields::ACCESS_MASTER_MEDIA_TYPE}:audio/* "\
    "OR #{Solr::Fields::PRESERVATION_MASTER_MEDIA_TYPE}:audio/*").
        where(Solr::Fields::PARENT_ITEM => :null).limit(1)
    @document_items = Item.where("#{Solr::Fields::ACCESS_MASTER_MEDIA_TYPE}:application/pdf "\
    "OR #{Solr::Fields::PRESERVATION_MASTER_MEDIA_TYPE}:application/pdf").
        where(Solr::Fields::PARENT_ITEM => :null).limit(1)
    @image_items = Item.where("#{Solr::Fields::ACCESS_MASTER_MEDIA_TYPE}:image/* "\
    "OR #{Solr::Fields::PRESERVATION_MASTER_MEDIA_TYPE}:image/*").
        where(Solr::Fields::PARENT_ITEM => :null).limit(1)
    @video_items = Item.where("#{Solr::Fields::ACCESS_MASTER_MEDIA_TYPE}:video/* "\
        "OR #{Solr::Fields::PRESERVATION_MASTER_MEDIA_TYPE}:video/*").
        where(Solr::Fields::PARENT_ITEM => :null).limit(1)

    # data for the nav bar search
    collection = self.collection
    if collection
      element_defs = collection.collection_def.metadata_profile.element_defs
    else
      element_defs = ElementDef.all
    end
    @searchable_collections = MedusaCollection.all.
        select{ |c| c.published and c.title.include?('Sanborn') } # TODO: fix once MED-400 is complete
    @elements_for_select = element_defs.where(searchable: true).order(:label).
        map{ |ed| [ ed.label, ed.solr_multi_valued_field ] }
    @elements_for_select.unshift([ 'Any Field', Solr::Fields::SEARCH_ALL ])
  end

  protected

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
        item = Item.find(params[:id])
        id = item.collection.id
      end
    end
    if id
      return MedusaCollection.find(id)
    end
    nil
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
        elsif params[:id]
          item = Item.find(params[:id])
          id = item.collection.id
        end
      end
      collection = CollectionDef.find_by_repository_id(id)
      theme = collection ? collection.theme || Theme.default : Theme.default
      pathname = theme ? File.join(Rails.root, theme.pathname, 'views') : nil
      prepend_view_path(pathname) if pathname
    end
  end

end
