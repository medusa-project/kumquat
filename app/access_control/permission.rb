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
# 2. Call sync_to_database() (restarting the app will also do this)
#
# To rename a permission:
#
# 1. Rename the string value of the Permissions constant
# 2. `rails generate migration RenameXPermissiontToY`
# 3. In the migration file, add
#    `execute("UPDATE permissions SET key = 'y' WHERE key = 'x'")`
# 4. rake db:migrate
#
class Permission < ApplicationRecord

  class Permissions
    ACCESS_CONTROL_PANEL = 'control_panel.access'
    MODIFY_COLLECTIONS = 'collections.modify'
    MODIFY_ITEMS = 'items.modify'
    MODIFY_ROLES = 'roles.modify'
    MODIFY_SETTINGS = 'settings.modify'
    MODIFY_USERS = 'users.modify'
    PURGE_ITEMS_FROM_COLLECTION = 'collections.purge_items'
  end

  has_and_belongs_to_many :roles

  validates :key, presence: true, length: { maximum: 255 },
            uniqueness: { case_sensitive: false }

  ##
  # Synchronizes the permissions defined in the Permissions class to the
  # database.
  #
  def self.sync_to_database
    logger = CustomLogger.instance

    const_keys = Permission::Permissions.constants(false).map do |const|
      Permission::Permissions.const_get(const)
    end

    ActiveRecord::Base.transaction do
      # Create permissions that don't exist in the database.
      logger.info('Permission.sync_to_database(): creating permissions')
      const_keys.each do |key|
        Permission.create!(key: key) unless Permission.find_by_key(key)
      end
      # Delete database permissions that no longer exist in the Permissions
      # class.
      logger.info('Permission.sync_to_database(): deleting obsolete '\
          'permissions')
      Permission.where('key NOT IN (?)', const_keys).delete_all

      # Ensure that the administrator role has all permissions.
      logger.info('Permission.sync_to_database(): granting all '\
          'permissions to the administrator role')
      admin = Role.find_by_key(:admin)
      if admin
        admin.permissions.clear
        Permission.all.each { |p| admin.permissions << p }
        admin.save!
      end
    end
  end

  Permission.sync_to_database

  ##
  # @return [String]
  #
  def name
    Permission::Permissions.constants(false).each do |const|
      if Permission::Permissions.const_get(const) == self.key
        return const.to_s.titleize
      end
    end
    key
  end

  ##
  # @return [String]
  #
  def to_s
    name
  end

end
