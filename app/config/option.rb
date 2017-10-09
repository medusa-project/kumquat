##
# Encapsulates a key-value option. Keys should be one of the Option::Keys
# constants. Values are stored as JSON internally. Simple values can be
# accessed using the boolean, integer, or string class methods.
#
class Option < ApplicationRecord

  class Keys
    ADMINISTRATOR_EMAIL = 'website.administrator.email'
    COPYRIGHT_STATEMENT = 'website.copyright_statement'
    FACET_TERM_LIMIT = 'website.facet_term_limit'
    WEBSITE_INTRO_TEXT = 'website.intro_text'
    OAI_PMH_ENABLED = 'oai_pmh.enabled'
    ORGANIZATION_NAME = 'organization.name'
    RESULTS_PER_PAGE = 'website.results_per_page'
    SERVER_STATUS = 'status'
    SERVER_STATUS_MESSAGE = 'status_message'
    WEBSITE_NAME = 'website.name'
  end

  # Values are stored in hashes keyed by this key.
  JSON_KEY = 'value'

  validates :key, presence: true, uniqueness: { case_sensitive: false }

  ##
  # @return The value associated with the given key as a Boolean.
  #
  def self.boolean(key)
    v = value_for(key)
    ['true', '1', true, 1].include?(v)
  end

  ##
  # @return The value associated with the given key as an integer. If there
  # is no value associated with the given key, returns 0.
  #
  def self.integer(key)
    v = value_for(key)
    v ? v.to_i : 0
  end

  ##
  # @param key [String]
  # @param value [Object]
  # @return [Option]
  #
  def self.set(key, value)
    option = Option.find_by_key(key)
    if option # if the option already exists
      if option.value != value # and it has a new value
        option.update!(value: value)
      end
    else # it doesn't exist, so create it
      option = Option.create!(key: key, value: value)
    end
    option
  end

  ##
  # @return The value associated with the given key as a string. If there is
  # no value associated with the given key, returns an empty string.
  #
  def self.string(key)
    v = value_for(key)
    v ? v.to_s : ''
  end

  def value
    json = JSON.parse(read_attribute(:value))
    json ? json[JSON_KEY] : nil
  end

  def value=(value)
    write_attribute(:value, JSON.generate({JSON_KEY => value}))
  end

  private

  def self.value_for(key)
    options = Option.where(key: key).limit(1)
    if options.any?
      begin
        json = JSON.parse(options[0].value)
        if json
          return json[JSON_KEY]
        end
      rescue
        return options[0].value
      end
    end
    nil
  end

end
