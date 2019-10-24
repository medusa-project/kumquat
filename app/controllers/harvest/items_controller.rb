module Harvest

  class ItemsController < AbstractHarvestController

    before_action :load_item

    ##
    # Responds to GET /harvest/items/:id
    #
    def show
      struct = {
          class:                   @item.class.to_s,
          id:                      @item.repository_id,
          public_uri:              item_url(self),
          collection_uri:          @item.collection ?
                                       collection_url(@item.collection, format: :json) : nil,
          normalized_start_date:   @item.start_date,
          normalized_end_date:     @item.end_date,
          normalized_latitude:     @item.latitude&.to_f,
          normalized_longitude:    @item.longitude&.to_f,
          variant:                 @item.variant,
          preservation_media_type: @item.binaries
                                       .where(master_type: Binary::MasterType::PRESERVATION).limit(1).first&.media_type,
          access_master_image:     access_master_image_block,
          elements:                @item.elements_in_profile_order(only_visible: true)
                                       .map{ |e| { name: e.name, value: e.value } },
          created_at:              @item.created_at,
          updated_at:              @item.updated_at
      }
      render json: struct
    end

    private

    def access_master_image_block
      struct = nil
      bin = @item.effective_image_binary
      if bin&.iiif_safe?
        struct = {
            id:         bin.cfs_file_uuid,
            object_uri: bin.uri,
            media_type: bin.media_type
        }
      end
      struct
    end

    def load_item
      @item = Item.find_by_repository_id(params[:id])
      raise ActiveRecord::RecordNotFound unless @item
    end

  end

end
