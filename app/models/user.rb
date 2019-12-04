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

  DEVELOPMENT_ADMIN_USERNAME = 'admin'
  DEVELOPMENT_USER_USERNAME  = 'user'

  has_and_belongs_to_many :item_sets
  has_and_belongs_to_many :roles

  validates :username, presence: true, length: { maximum: 50 },
            uniqueness: { case_sensitive: false }

  before_create :reset_api_key

  def has_permission?(key)
    return true if self.medusa_admin?
    self.roles_having_permission(key).any?
  end

  alias_method :can?, :has_permission?

  def medusa_admin?
    if Rails.env.development? or Rails.env.test?
      return self.username == DEVELOPMENT_ADMIN_USERNAME
    end
    group = Configuration.instance.medusa_admins_group
    LdapQuery.new.is_member_of?(group, self.username)
  end

  def medusa_user?
    if Rails.env.development? or Rails.env.test?
      return self.username == DEVELOPMENT_USER_USERNAME
    end
    group = Configuration.instance.medusa_users_group
    LdapQuery.new.is_member_of?(group, self.username)
  end

  def reset_api_key
    self.api_key = SecureRandom.base64
  end

  def roles_having_permission(key)
    self.roles.select{ |r| r.has_permission?(key) }
  end

  def to_param
    username
  end

  def to_s
    username
  end

end
