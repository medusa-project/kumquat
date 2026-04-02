class RepositoriesController < WebsiteController 
  PERMITTED_PARAMS = [{ fq: [] }, :id, :q, :sort, :start, :utf8, :commit, :'dl-current-path', :_, :format]
  before_action :set_sanitized_params
  
  include SearchHelper

  def index
    # Get all collections that are part of Digital Special Collections
    collections = Collection.where(public_in_medusa: true, published_in_dls: true)
                            .where.not(medusa_repository_id: nil)
    
    # Get unique repositories from these collections
    repositories_hash = {}
    collections.each do |collection|
      begin
        repository = collection.medusa_repository
        if repository
          repositories_hash[repository.id] = repository
        end
      rescue => e
        Rails.logger.warn("Could not fetch repository for collection #{collection.repository_id}: #{e.message}")
      end
    end
    
    # Convert to array and sort by title
    @repositories = repositories_hash.values.sort_by(&:title)
  end

  def show 
    begin
      # Get distinct repository IDs from public collections (optimized to reduce API calls)
      repository_ids = Collection.where(public_in_medusa: true, published_in_dls: true)
                                .where.not(medusa_repository_id: nil)
                                .distinct
                                .pluck(:medusa_repository_id)
      
      # Find the repository matching the parameterized title
      @repository = nil
      repository_ids.each do |repo_id|
        repository = Medusa::Repository.with_id(repo_id)
        if repository && repository.title.parameterize == params[:id]
          @repository = repository
          break
        end
      end
      
      raise ActiveRecord::RecordNotFound unless @repository
      
      # Get all public collections belonging to this repository
      @collections = Collection.where(medusa_repository_id: @repository.id,
                                      public_in_medusa: true, 
                                      published_in_dls: true)
                               .includes(:elements)
                               .joins("LEFT JOIN entity_elements ON entity_elements.collection_id = collections.id AND entity_elements.name = 'title'")
                               .order('entity_elements.value ASC NULLS FIRST')
      
      # Calculate total items count (collections + their items)
      @total_items_count = @collections.count + @collections.sum(&:num_public_objects)
      
      # Handle search if query is present
      if @permitted_params[:q].present?
        @start = [@permitted_params[:start].to_i.abs, max_start].min 
        @limit = window_size

        # Repository-scoped search
        search = SpecialCollectionSearch.new(
          query: @permitted_params[:q],
          start: @start,
          limit: @limit,
          facet_filters: @permitted_params[:fq],
          repository_id: @repository.id
        )
        search.execute!

        @results = search.results
        @count = search.count
        @collection_count = search.collection_count
        @item_count = search.item_count
        @facets = search.facets

        @current_page = (@start / @limit) + 1
        @num_results_shown = [@results.count, @limit].min
      end
      
    rescue => e
      Rails.logger.error("Repository with title '#{params[:id]}' not found: #{e.message}")
      raise ActiveRecord::RecordNotFound
    end
    
    respond_to do |format|
      format.html
      format.js
    end
  end

  private 
  def set_sanitized_params
    @permitted_params = params.permit(PERMITTED_PARAMS)
  end

  def window_size
    40 
  end

  def max_start
    9960 
  end
end