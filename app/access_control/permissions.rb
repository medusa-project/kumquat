##
# Contains constants for all permissions understood by the application.
#
# To check whether a user has a given permission, use {User#has_permission?}.
#
# N.B.: When a constant is added, removed, or modified, the application
# configuration must be updated to reflect the change.
#
class Permissions

  MODIFY_COLLECTIONS          = 'collections.modify'
  MODIFY_ELEMENTS             = 'elements.modify'
  MODIFY_ITEMS                = 'items.modify'
  MODIFY_METADATA_PROFILES    = 'metadata_profiles.modify'
  MODIFY_SETTINGS             = 'settings.modify'
  MODIFY_USERS                = 'users.modify'
  PURGE_ITEMS_FROM_COLLECTION = 'collections.purge_items'
  VIEW_USERS                  = 'users.view'

  ##
  # @return [Enumerable<String>] All class constant values.
  #
  def self.all
    self.constants.map{ |c| self.const_get(c) }
  end

end
