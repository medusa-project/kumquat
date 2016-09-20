##
# Pseudo-interface to be included by models that support role-based
# authorization.
#
module AuthorizableByRole

  ##
  # @return [Enumerable<Role>] Allowed roles, including any inherited from
  #                            ancestors, if applicable.
  #
  def effective_allowed_roles
    super
  end

  ##
  # @return [Enumerable<Role>] Denied roles, including any inherited from
  #                            ancestors, if applicable.
  #
  def effective_denied_roles
    super
  end

end