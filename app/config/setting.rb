# frozen_string_literal: true

##
# Encapsulates a key-value setting. Keys should be one of the {Setting::Keys}
# constants. Values are stored as JSON internally. Simple values can be
# accessed using the boolean, integer, or string class methods.
#
class Setting < ApplicationRecord

  class Keys
    ADMINISTRATOR_EMAIL   = 'website.administrator.email'
    COPYRIGHT_STATEMENT   = 'website.copyright_statement'
    DEFAULT_RESULT_WINDOW = 'website.results_per_page'
    FACET_TERM_LIMIT      = 'website.facet_term_limit'
    ORGANIZATION_NAME     = 'organization.name'
    WEBSITE_NAME          = 'website.name'
  end

  # Values are stored in hashes keyed by this key.
  JSON_KEY = 'value'

  validates :key, presence: true, uniqueness: { case_sensitive: false }

  ##
  # @param key [String]
  # @param default [Boolean] Value to return if there is no value for the given
  #                          key.
  # @return [Boolean] Value associated with the given key as a boolean, or nil
  #                   if there is no value associated with the given key.
  #
  def self.boolean(key, default = nil)
    v = value_for(key)
    v ? ['true', '1', true, 1].include?(v) : default
  end

  ##
  # @param key [String]
  # @param default [Boolean] Value to return if there is no value for the given
  #                          key.
  # @return [Integer] Value associated with the given key as an integer, or nil
  #                   if there is no value associated with the given key.
  #
  def self.integer(key, default = nil)
    v = value_for(key)
    v ? v.to_i : default
  end

  ##
  # @param key [String]
  # @param value [Object]
  # @return [Setting]
  #
  def self.set(key, value)
    setting = Setting.find_by_key(key)
    if setting # if the setting already exists
      if setting.value != value # and it has a new value
        setting.update!(value: value)
      end
    else # it doesn't exist, so create it
      setting = Setting.create!(key: key, value: value)
    end
    setting
  end

  ##
  # @param key [String]
  # @param default [Boolean] Value to return if there is no value for the given
  #                          key.
  # @return [String,nil] Value associated with the given key as a string, or nil
  #                      if there is no value associated with the given key.
  #
  def self.string(key, default = nil)
    v = value_for(key)
    v ? v.to_s : default
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
    opt = Setting.where(key: key).limit(1).first
    opt&.value
  end

end
