##
# Contains constants for all permissions understood by the application.
#
# To check whether a user has a given permission, use {User#has_permission?}.
#
class Permissions

  ACCESS_CONTROL_PANEL        = 'control_panel.access'
  MODIFY_COLLECTIONS          = 'collections.modify'
  MODIFY_ITEMS                = 'items.modify'
  MODIFY_ROLES                = 'roles.modify'
  MODIFY_SETTINGS             = 'settings.modify'
  MODIFY_USERS                = 'users.modify'
  PURGE_ITEMS_FROM_COLLECTION = 'collections.purge_items'

end
