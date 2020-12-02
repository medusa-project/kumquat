##
# Application user. 
#
# # Attributes
#
# * `api_key`    Used as a secret/password for accessing the HTTP API.
# * `created_at` Managed by ActiveRecord.
# * `human`      Whether the user is associated with a human. Non-human users
#                may be used by scripts etc.
# * `updated_at` Managed by ActiveRecord.
# * `username`   Username. For UIUC users, this is the NetID.
#
class User < ApplicationRecord

  # Username of a Medusa "user" in development & test environments.
  DEVELOPMENT_USER_USERNAME      = 'user'

  # Username of a Medusa "admin" in development & test environments.
  DEVELOPMENT_ADMIN_USERNAME     = 'admin'

  # Username of a Medusa "super admin" in development & test environments.
  DEVELOPMENT_SUPERUSER_USERNAME = 'super'

  LDAP_CACHE_TTL = 12.hours

  has_and_belongs_to_many :item_sets

  validates :username, presence: true, length: { maximum: 50 },
            uniqueness: { case_sensitive: false }

  before_create :reset_api_key

  ##
  # @param key [String] One of the {Permissions} constant values.
  # @return [Boolean]
  #
  def has_permission?(key)
    config = Configuration.instance
    if medusa_superuser?
      return true
    elsif medusa_admin?
      return config.medusa_admins_group[:permissions].include?(key)
    elsif medusa_user?
      return config.medusa_users_group[:permissions].include?(key)
    end
    false
  end

  alias_method :can?, :has_permission?

  ##
  # @return [Boolean]
  #
  def medusa_admin?
    if Rails.env.development? or Rails.env.test?
      return [DEVELOPMENT_ADMIN_USERNAME,
              DEVELOPMENT_SUPERUSER_USERNAME].include?(self.username)
    end
    Rails.cache.fetch("user.#{username}.medusa_admin",
                      expires_in: LDAP_CACHE_TTL) do
      group = Configuration.instance.medusa_admins_group[:name]
      LdapQuery.new.is_member_of?(group, self.username)
    end
  end

  ##
  # @return [Boolean]
  #
  def medusa_superuser?
    if Rails.env.development? or Rails.env.test?
      return self.username == DEVELOPMENT_SUPERUSER_USERNAME
    end
    Rails.cache.fetch("user.#{username}.medusa_superuser",
                      expires_in: LDAP_CACHE_TTL) do
      group = Configuration.instance.medusa_superusers_group[:name]
      LdapQuery.new.is_member_of?(group, self.username)
    end
  end

  ##
  # @return [Boolean]
  #
  def medusa_user?
    if Rails.env.development? or Rails.env.test?
      return [DEVELOPMENT_USER_USERNAME, DEVELOPMENT_ADMIN_USERNAME,
              DEVELOPMENT_SUPERUSER_USERNAME].include?(self.username)
    end
    Rails.cache.fetch("user.#{username}.medusa_user",
                      expires_in: LDAP_CACHE_TTL) do
      group = Configuration.instance.medusa_users_group[:name]
      LdapQuery.new.is_member_of?(group, self.username)
    end
  end

  def reset_api_key
    self.api_key = SecureRandom.base64
  end

  def to_param
    username
  end

  def to_s
    username
  end

end
