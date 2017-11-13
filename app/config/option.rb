##
# Encapsulates a key-value option. Keys should be one of the Option::Keys
# constants. Values are stored as JSON internally. Simple values can be
# accessed using the boolean, integer, or string class methods.
#
class Option < ApplicationRecord

  class Keys
    ADMINISTRATOR_EMAIL = 'website.administrator.email'
    COPYRIGHT_STATEMENT = 'website.copyright_statement'
    CURRENT_INDEX_VERSION = 'elasticsearch.current_index_version'
    DEFAULT_RESULT_WINDOW = 'website.results_per_page'
    FACET_TERM_LIMIT = 'website.facet_term_limit'
    OAI_PMH_ENABLED = 'oai_pmh.enabled'
    ORGANIZATION_NAME = 'organization.name'
    SERVER_STATUS = 'status'
    SERVER_STATUS_MESSAGE = 'status_message'
    WEBSITE_INTRO_TEXT = 'website.intro_text'
    WEBSITE_NAME = 'website.name'
  end

  # Values are stored in hashes keyed by this key.
  JSON_KEY = 'value'

  validates :key, presence: true, uniqueness: { case_sensitive: false }

  ##
  # @return [Boolean] Value associated with the given key as a boolean, or nil
  #                   if there is no value associated with the given key.
  #
  def self.boolean(key)
    v = value_for(key)
    v ? ['true', '1', true, 1].include?(v) : nil
  end

  ##
  # @return [Integer] Value associated with the given key as an integer, or nil
  #                   if there is no value associated with the given key.
  #
  def self.integer(key)
    v = value_for(key)
    v ? v.to_i : nil
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
  # @return [String,nil] Value associated with the given key as a string, or nil
  #                      if there is no value associated with the given key.
  #
  def self.string(key)
    v = value_for(key)
    v ? v.to_s : nil
  end

  ##
  # @return [Object] Raw value.
  #
  def value
    json = JSON.parse(read_attribute(:value))
    json[JSON_KEY]
  end

  ##
  # @param value [Object] Raw value to set.
  #
  def value=(value)
    write_attribute(:value, JSON.generate({JSON_KEY => value}))
  end

  private

  def self.value_for(key)
    opt = Option.where(key: key).limit(1).first
    opt&.value
  end

end
