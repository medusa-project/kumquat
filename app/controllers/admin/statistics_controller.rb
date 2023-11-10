module Admin

  class StatisticsController < ControlPanelController

    LOGGER = CustomLogger.new(StatisticsController)

    def index
      # Collections section
      collections_time = measure_time do
        @num_collections        = Collection.count
        @num_public_collections = Collection.where(public_in_medusa: true,
                                                   published_in_dls: true).count
      end

      # Items section
      items_time = measure_time do
        @num_objects         = Item.num_objects
        @num_items           = Item.count
        @num_free_form_items = Item.num_free_form_items
      end

      # Binaries section
      binaries_time = measure_time do
        @num_binaries                    = Binary.count
        @total_binary_size               = Binary.sum(:byte_size)
        @preservation_master_binary_size = Binary.where(master_type: Binary::MasterType::PRESERVATION).sum(:byte_size)
        @access_master_binary_size       = Binary.where(master_type: Binary::MasterType::ACCESS).sum(:byte_size)

        sql = "SELECT regexp_matches(lower(object_key),'\\.(\\w+)$') AS extension,
          COUNT(id) AS count
        FROM binaries
        WHERE object_key ~ '\\.'
        GROUP BY extension
        ORDER BY extension ASC"
        @extension_counts = ActiveRecord::Base.connection.execute(sql)
      end

      # Metadata section
      metadata_time = measure_time do
        @num_available_elements = Element.count
        @num_ascribed_elements  = ItemElement.count + CollectionElement.count
        @num_metadata_profiles  = MetadataProfile.count
        @num_agents             = Agent.count
        @num_vocabularies       = Vocabulary.count
      end

      round = 2
      LOGGER.debug('index(): [collections: %ss] [items: %ss] [binaries: %ss] '\
                   '[metadata: %ss]',
                   collections_time.round(round),
                   items_time.round(round),
                   binaries_time.round(round),
                   metadata_time.round(round))
    end

    private

    ##
    # @return [Float] Seconds.
    #
    def measure_time(&block)
      start = Time.now
      yield
      Time.now - start
    end

  end

end
