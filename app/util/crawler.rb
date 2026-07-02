##
# Crawler class to load and memoize the content of crawlers.yml file.
# 

class Crawler 
  ## 
  # begin..end block to memoize user_agents array to avoid reloading multiple times
  # load crawlers.yml content; empty file yields an empty array,
  # while a missing file raises Errno::ENOENT (fails loudly). This would happen if the file was deleted/moved, 
  # or not deployed for some reason.
  # iterate over the crawler.yml file entries, convert to string, strip whitespace, downcase and reject blank entries
  def self.user_agents
    @user_agents ||= begin
      entries = YAML.load_file(Rails.root.join('config', 'crawlers.yml')) || []
      entries.map { |user_agent| user_agent.to_s.strip.downcase }.reject(&:blank?)
    end
  end

  def self.matches?(user_agent)
    # false for blank user agent
    return false if user_agent.blank?

    # otherwise downcase the given user agent 
    # and check if it includes any of the elements in the user_agents array
    ua = user_agent.downcase 
    user_agents.any? { | crawler| ua.include?(crawler) }
  end