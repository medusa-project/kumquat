module Search 
  include ActiveSupport::Concern

  SIMPLE_SEARCH_PARAMS = [:q]
  RESULTS_PARAMS = [:direction, { fq: [] }, :sort, :page, :per_page]

  def self.advanced_search_params 
    #todo
  end

  def process_search_query(relation)
    permitted_params = params.permit!
    query = permitted_params[:query]
    field = permitted_params[:field] # e.g., "All fields" or "Title"
    match_type = permitted_params[:match_type] # e.g., "all", "any", "exact", "none"

    # Map user-facing fields to indexed fields
    field_map = Element.searchable_field_map

    # Determine fields to search
    fields_to_search = field == "All fields" ? field_map.values : [field_map[field]].compact

    # Build query based on match type
    terms = query.to_s.strip.split
    case match_type
    when "all"
      search_query = terms.map { |t| "+#{t}" }.join(" ")
    when "any"
      search_query = terms.join(" ")
    when "exact"
      search_query = "\"#{query}\""
    when "none"
      search_query = terms.map { |t| "-#{t}" }.join(" ")
    else
      search_query = query
    end

    # Apply to relation
    fields_to_search.each do |f|
      relation.multi_query(f, search_query)
    end
  end
end