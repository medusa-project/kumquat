##
# Module / pseudo-interface to be included by models that support role-based
# authorization.
#
module AuthorizableByRole

  ##
  # @param roles [Enumerable<Role>]
  # @return [Boolean] True if no roles are provided or if any role authorizes
  #                   the entity; false otherwise.
  #
  def authorized_by_any_roles?(roles)
    return self.effective_allowed_roles.empty? if !roles or roles.empty?
    roles.each { |role| return true if authorized_by_role?(role) }
    false
  end

  ##
  # @param role [Role]
  # @return [Boolean]
  #
  def authorized_by_role?(role)
    if self.effective_denied_roles.map(&:key).include?(role.key)
      return false
    elsif self.effective_allowed_roles.any? and
        !self.effective_allowed_roles.map(&:key).include?(role.key)
      return false
    end
    true
  end

  ##
  # Stub implementation that calls super.
  #
  # @return [Enumerable<Role>] Allowed roles, including any inherited from
  #                            ancestors, if applicable.
  #
  def effective_allowed_roles
    super
  end

  ##
  # Stub implementation that calls super.
  #
  # @return [Enumerable<Role>] Denied roles, including any inherited from
  #                            ancestors, if applicable.
  #
  def effective_denied_roles
    super
  end

end