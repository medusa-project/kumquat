module Harvest

  class CollectionsController < AbstractHarvestController

    before_action :load_collection

    ##
    # Responds to GET /harvest/collections/:id
    #
    def show
      parent = @collection.parents.first
      parent = parent ? { id: parent.repository_id,
                          uri: collection_url(parent) } : nil
      struct = {
          class:                   @collection.class.to_s,
          id:                      @collection.repository_id,
          external_id:             @collection.external_id,
          public_uri:              collection_url(@collection),
          access_uri:              @collection.access_url,
          physical_collection_uri: @collection.physical_collection_url,
          repository_title:        @collection.medusa_repository.title,
          resource_types:          @collection.resource_types,
          access_systems:          @collection.access_systems,
          package_profile:         @collection.package_profile&.name,
          access_master_image:     access_master_image_block,
          elements:                @collection.elements_in_profile_order(only_visible: true)
                                       .map{ |e| { name: e.name, value: e.value } },
          parent:                  parent,
          created_at:              @collection.created_at,
          updated_at:              @collection.updated_at
      }
      render json: struct
    end

    private

    def access_master_image_block
      struct = nil
      bin = @collection.effective_representative_image_binary
      if bin&.image_server_safe?
        struct = {
            id:         bin.cfs_file_uuid,
            object_uri: bin.uri,
            media_type: bin.media_type
        }
      end
      struct
    end

    def load_collection
      @collection = Collection.find_by_repository_id(params[:id])
      raise ActiveRecord::RecordNotFound unless @collection
    end

  end

end
