##
# Base controller for all controllers related to the public website.
#
class WebsiteController < ApplicationController

  before_action :prepend_view_paths

  def setup
    super

    @num_items = Item.where(Item::SolrFields::PARENT_ITEM => :null).count

    @audio_items = Item.where("#{Item::SolrFields::ACCESS_MASTER_MEDIA_TYPE}:audio/* "\
    "OR #{Item::SolrFields::PRESERVATION_MASTER_MEDIA_TYPE}:audio/*").
        where(Item::SolrFields::PARENT_ITEM => :null).limit(1)
    @document_items = Item.where("#{Item::SolrFields::ACCESS_MASTER_MEDIA_TYPE}:application/pdf "\
    "OR #{Item::SolrFields::PRESERVATION_MASTER_MEDIA_TYPE}:application/pdf").
        where(Item::SolrFields::PARENT_ITEM => :null).limit(1)
    @image_items = Item.where("#{Item::SolrFields::ACCESS_MASTER_MEDIA_TYPE}:image/* "\
    "OR #{Item::SolrFields::PRESERVATION_MASTER_MEDIA_TYPE}:image/*").
        where(Item::SolrFields::PARENT_ITEM => :null).limit(1)
    @video_items = Item.where("#{Item::SolrFields::ACCESS_MASTER_MEDIA_TYPE}:video/* "\
        "OR #{Item::SolrFields::PRESERVATION_MASTER_MEDIA_TYPE}:video/*").
        where(Item::SolrFields::PARENT_ITEM => :null).limit(1)

    # Data for the nav bar search. If there is a single collection in the
    # current context, use the fields of its metadata profile. Otherwise, use
    # the fields of the default metadata profile.
    collection = self.collection
    if collection
      element_defs = collection.effective_metadata_profile.element_defs
    else
      element_defs = MetadataProfile.where(default: true).limit(1).first.
          element_defs
    end
    @searchable_collections = Collection.where(published_in_dls: true)
    @elements_for_select = element_defs.where(searchable: true).order(:label).
        map{ |ed| [ ed.label, ed.solr_multi_valued_field ] }
    @elements_for_select.unshift([ 'Any Field', Entity::SolrFields::SEARCH_ALL ])
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
      return Collection.find_by_repository_id(id)
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
      collection = Collection.find_by_repository_id(id)
      theme = collection ? collection.theme || Theme.default : Theme.default
      pathname = theme ? File.join(Rails.root, theme.pathname, 'views') : nil
      prepend_view_path(pathname) if pathname
    end
  end

end
