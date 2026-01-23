class RepositoriesController < WebsiteController 
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
      # Get all repositories to find the one matching the parameterized title
      collections = Collection.where(public_in_medusa: true, published_in_dls: true)
                              .where.not(medusa_repository_id: nil)
      
      @repository = nil
      collections.each do |collection|
        repository = collection.medusa_repository
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
                               .order('title ASC')
      
    rescue => e
      Rails.logger.error("Repository with title '#{params[:id]}' not found: #{e.message}")
      raise ActiveRecord::RecordNotFound
    end
  end
end