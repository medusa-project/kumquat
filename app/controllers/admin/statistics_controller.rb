module Admin

  class StatisticsController < ControlPanelController

    def index
      # Collections section
      @num_collections = Collection.count
      @num_public_collections = Collection.where(published_in_medusa: true,
                                                 published_in_dls: true).count

      # Items section
      @num_objects = Item.num_objects
      @num_items = Item.count
      @num_free_form_items = Item.num_free_form_items

      # Binaries section
      @num_binaries = Binary.count

      sql = "SELECT regexp_matches(lower(repository_relative_pathname),'\\.(\\w+)$') AS extension,
        COUNT(id) AS count
      FROM binaries
      WHERE repository_relative_pathname ~ '\\.'
      GROUP BY extension
      ORDER BY extension ASC"
      @extension_counts = ActiveRecord::Base.connection.execute(sql)

      # Metadata section
      @num_available_elements = Element.count
      @num_ascribed_elements = ItemElement.count + CollectionElement.count
      @num_metadata_profiles = MetadataProfile.count
      @num_agents = Agent.count
      @num_vocabularies = Vocabulary.count

      # Users section
      @num_users = User.count
    end

  end

end
