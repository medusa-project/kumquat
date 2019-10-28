##
# Key-value structure to support basic database-based caching.
#
class CacheItem < ApplicationRecord

  ##
  # Enum-like class of standardized cache keys.
  #
  class Key
    GATEWAY_ITEM_COUNT = 'gateway.item_count'
  end

  LOGGER = CustomLogger.new(CacheItem)

  ##
  # @param key [String] Cache key.
  # @param max_age [Integer] Max age in seconds.
  # @param block [Block] Block to invoke if no value is found for the given
  #                      key, or if the value is older than max_age. The
  #                      return value is cached.
  # @return [String] Cache item value.
  #
  def self.get_or(key, max_age = 0, &block)
    item = CacheItem.find_by_key(key)
    if item
      if Time.now - item.updated_at > max_age
        LOGGER.debug("Miss for #{key} (expired)")
        item.update!(key: key, value: block.call) if block_given?
      else
        LOGGER.debug("Hit for #{key}")
      end
    else
      LOGGER.debug("Miss for #{key} (does not exist)")
      item = CacheItem.create!(key: key, value: block.call) if block_given?
    end
    item.value
  end

end
