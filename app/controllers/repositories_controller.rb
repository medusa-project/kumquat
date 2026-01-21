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
    
  end
end