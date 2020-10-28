class UrlUtils

  ##
  # Parses the query portion of a URL into a hash.
  #
  # @param url [String,URI] URL
  # @return [Hash<String,String>]
  #
  def self.parse_query(url)
    url = URI.parse(url) unless url.kind_of?(URI)
    Rack::Utils.parse_nested_query(url.query).stringify_keys || {}
  end

end