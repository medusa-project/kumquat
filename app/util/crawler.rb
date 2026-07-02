##
# Crawler class to load and memoize the content of crawlers.yml file.
# 

class Crawler 
  ## 
  # begin..end block to memoize user_agents array to avoid reloading multiple times
  # load crawlers.yml content or return an empty array if no file found 
  # iterate over the crawler.yml file entries, convert to string, strip whitespace, downcase and reject blank entries
  def self.user_agents
    @user_agents ||= begin
      entries = YAML.load_file(Rails.root.join('config', 'crawlers.yml')) || []
      entries.map { |user_agent| user_agent.to_s.strip.downcase }.reject(&:blank?)
    end
  end