module Harvest

  class HarvestController < AbstractHarvestController

    WINDOW_SIZE = 100

    ##
    # Responds to GET /harvest
    #
    def index
      @start = params[:start].to_i

      # EntityRelation will search across entity classes and return Items and
      # and Collections.
      relation = EntityRelation.new.
          bypass_authorization(true).
          # exclude all variants except File. (Only compound object items have
          # these variants.)
          include_types(Collection, Item).
          exclude_item_variants(*Item::Variants::all.reject{ |v| v == Item::Variants::FILE }).
          aggregations(false).
          order(Item::IndexFields::REPOSITORY_ID).
          start(@start).
          limit(WINDOW_SIZE)

      if params[:last_modified_before].present?
        relation = relation.last_modified_before(Time.at(params[:last_modified_before].to_i))
      end
      if params[:last_modified_after].present?
        relation = relation.last_modified_after(Time.at(params[:last_modified_after].to_i))
      end

      @entities = relation.to_a
      @count    = relation.count

      render json: {
          start: @start,
          windowSize: WINDOW_SIZE,
          numResults: @count,
          results: @entities.map { |entity|
            case entity.class.to_s
            when 'Collection'
              uri = harvest_collection_url(entity)
            when 'Item'
              uri = harvest_item_url(entity)
            else
              uri = nil
            end
            {
                id: entity.repository_id,
                uri: uri
            }
          }
      }
    end

  end

end