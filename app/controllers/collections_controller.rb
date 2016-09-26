class CollectionsController < WebsiteController

  before_action :load_collection, only: :show
  before_action :authorize_collection, only: :show

  def index
    @collections = Collection.solr.
        where(Collection::SolrFields::PUBLISHED => true).
        where(Collection::SolrFields::ACCESS_URL => :not_null).
        facetable_fields(Collection::solr_facet_fields.map{ |e| e[:name] }).
        order(Collection::SolrFields::TITLE).
        limit(99999)

    roles = request_roles.map(&:key)
    if roles.any?
      # Include documents that have allowed roles matching one of the user
      # roles, or that have no effective allowed roles.
      @collections = @collections.
          where("(#{Collection::SolrFields::ALLOWED_ROLES}:(#{roles.join(' ')}) "\
          "OR *:* -#{Collection::SolrFields::ALLOWED_ROLES}:[* TO *])")
      # Exclude documents that have denied roles matching one of the user
      # roles.
      @collections = @collections.
          where("-#{Collection::SolrFields::DENIED_ROLES}:(#{roles.join(' ')})")
    end

    if params[:fq].respond_to?(:each)
      params[:fq].each { |fq| @collections = @collections.facet(fq) }
    else
      @collections = @collections.facet(params[:fq])
    end

    fresh_when(etag: @collections) if Rails.env.production?

    respond_to do |format|
      format.html
      format.json do
        render json: @collections.to_a.map do |c|
          { id: c.repository_id, url: collection_url(c) }
        end
      end
    end
  end

  def show
    fresh_when(etag: @collection) if Rails.env.production?

    respond_to do |format|
      format.html do
        begin
          @representative_image_bytestream =
              @collection.representative_image_bytestream
        rescue => e
          Rails.logger.error("#{e}")
        end
      end
      format.json { render json: @collection.decorate }
    end
  end

  private

  def authorize_collection
    return unless authorize(@collection)
  end

  def load_collection
    @collection = Collection.find_by_repository_id(params[:id])
    raise ActiveRecord::RecordNotFound unless @collection
  end

end
