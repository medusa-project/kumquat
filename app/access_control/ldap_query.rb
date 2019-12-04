##
# This code forked from:
# https://github.com/medusa-project/medusa-collection-registry/blob/0c8dcecc6866290f861de7d508feaada69b1233b/app/models/ldap_query.rb
#
# ... and modified to use Net::HTTP rather than adding a dependency on another
# HTTP client.
#
class LdapQuery

  delegate :ldap_cache_key, to: :class

  def is_member_of?(group, net_id)
    return false unless group.present?
    json = Rails.cache.fetch(ldap_cache_key(net_id)) do
      "{}"
    end
    hash = JSON.parse(json)
    if hash.has_key?(group)
      hash[group]
    else
      uri      = URI.parse(ldap_url(group, net_id))
      http     = Net::HTTP.new(uri.host, uri.port)
      request  = Net::HTTP::Get.new(uri.request_uri)
      response = http.request(request)
      if response.code.to_i < 300
        (response.body == 'TRUE').tap do |is_member|
          hash[group] = is_member
          Rails.cache.write(ldap_cache_key(net_id), hash.to_json,
                            expires_in: 1.day, race_condition_ttl: 10.seconds)
        end
      else
        # don't authenticate, but also don't cache, in this case
        false
      end
    end
  end

  def ldap_url(group, net_id)
    "http://quest.grainger.uiuc.edu/directory/ad/#{net_id}/ismemberof/#{URI.encode(group)}"
  end

  def self.ldap_cache_key(net_id)
    "ldap_#{net_id}"
  end

  def self.reset_cache(net_id = nil)
    Rails.cache.delete(ldap_cache_key(net_id))
  end

end
