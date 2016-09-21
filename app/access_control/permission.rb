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
# 1. Assign it a constant and string value corresponding to its key
# 2. Create a Permission object with that key and save it
# 3. Add its key to the strings file(s) in config/locales
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


  def name
    I18n.t "permission_#{key.gsub('.', '_')}"
  end

  def readonly?
    !new_record?
  end

end
