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

  DEVELOPMENT_ADMIN_USERNAME     = 'admin'
  DEVELOPMENT_SUPERUSER_USERNAME = 'super'
  DEVELOPMENT_USER_USERNAME      = 'user'

  has_and_belongs_to_many :item_sets

  validates :username, presence: true, length: { maximum: 50 },
            uniqueness: { case_sensitive: false }

  before_create :reset_api_key

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

  def medusa_admin?
    if Rails.env.development? or Rails.env.test?
      return [DEVELOPMENT_ADMIN_USERNAME,
              DEVELOPMENT_SUPERUSER_USERNAME].include?(self.username)
    end
    group = Configuration.instance.medusa_admins_group[:name]
    LdapQuery.new.is_member_of?(group, self.username)
  end

  def medusa_superuser?
    if Rails.env.development? or Rails.env.test?
      return self.username == DEVELOPMENT_SUPERUSER_USERNAME
    end
    group = Configuration.instance.medusa_superusers_group[:name]
    LdapQuery.new.is_member_of?(group, self.username)
  end

  def medusa_user?
    if Rails.env.development? or Rails.env.test?
      return [DEVELOPMENT_USER_USERNAME, DEVELOPMENT_ADMIN_USERNAME,
              DEVELOPMENT_SUPERUSER_USERNAME].include?(self.username)
    end
    group = Configuration.instance.medusa_users_group[:name]
    LdapQuery.new.is_member_of?(group, self.username)
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
