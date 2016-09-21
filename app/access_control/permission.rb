##
# Encapsulates a permission in a role-based access control (RBAC) system.
# Permissions can be owned by zero or more roles and a role can have zero or
# more permissions.
#
# Permissions are basically just strings; it's up to the application to decide
# what permissions to define.
#
# To check whether a user or role has a given permission, use
# `User.has_permission?` or `Role.has_permission?`.
#
# To add a permission:
#
# 1. Add a constant for it to the Permissions class
# 2. Add its label to the strings file(s) in config/locales
# 3. Call sync_to_database() (restarting the app will also do this)
#
class Permission < ActiveRecord::Base

  class Permissions
    ACCESS_CONTROL_PANEL = 'control_panel.access'
    CREATE_ROLE = 'roles.create'
    CREATE_USER = 'users.create'
    DELETE_ROLE = 'roles.delete'
    DELETE_USER = 'users.delete'
    DISABLE_USER = 'users.disable'
    ENABLE_USER = 'users.enable'
    PUBLISH_COLLECTION = 'collections.publish'
    REINDEX = 'reindex'
    UNPUBLISH_COLLECTION = 'collections.unpublish'
    UPDATE_COLLECTION = 'collections.update'
    UPDATE_ITEM = 'items.update'
    UPDATE_ROLE = 'roles.update'
    UPDATE_SELF = 'users.update_self'
    UPDATE_SETTINGS = 'settings.update'
    UPDATE_USER = 'users.update'
    VIEW_USERS = 'users.view'
  end

  has_and_belongs_to_many :roles

  validates :key, presence: true, length: { maximum: 255 },
            uniqueness: { case_sensitive: false }

  ##
  # Synchronizes the permissions defined in the Permissions class to the
  # database.
  #
  def self.sync_to_database
    const_keys = Permission::Permissions.constants(false).map do |const|
      Permission::Permissions.const_get(const)
    end

    ActiveRecord::Base.transaction do
      # Create permissions that don't exist in the database.
      Rails.logger.info('Permission.sync_to_database(): creating permissions')
      const_keys.each do |key|
        Permission.create!(key: key) unless Permission.find_by_key(key)
      end
      # Delete database permissions that no longer exist in the Permissions
      # class.
      Rails.logger.info('Permission.sync_to_database(): deleting obsolete permissions')
      Permission.where('key NOT IN (?)', const_keys).delete_all
    end
  end

  Permission.sync_to_database

  ##
  # @return [String]
  #
  def name
    I18n.t "permission_#{key.gsub('.', '_')}"
  end

  def readonly?
    !new_record?
  end

end
