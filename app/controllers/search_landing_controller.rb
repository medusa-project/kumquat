class SearchLandingController < WebsiteController 
  PERMITTED_PARAMS = [{ fq: [] }, :q, :sort, :start, :utf8, :commit, :tab]

  before_action :set_sanitized_params
  def index 
    
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