##
# Module to be included by models that support host-based authorization.
#
module AuthorizableByHost

  ##
  # @param host_groups [Enumerable<HostGroup>] Client host group(s).
  # @return [Boolean] True if no host groups are provided or if any of them
  #                   authorize the entity; false otherwise.
  #
  def authorized_by_any_host_groups?(host_groups)
    return self.effective_allowed_host_groups.empty? if host_groups&.empty?
    host_groups.each do |group|
      return true if authorized_by_host_group?(group)
    end
    false
  end

  ##
  # @param host_group [HostGroup]
  # @return [Boolean]
  #
  def authorized_by_host_group?(host_group)
    if self.effective_allowed_host_groups.any? &&
        self.effective_allowed_host_groups.where(key: host_group.key).count == 0
      return false
    end
    true
  end

  ##
  # Stub implementation that calls super.
  #
  # @return [Enumerable<HostGroup>] Allowed host groups, including any
  #         inherited from ancestors, if applicable.
  #
  def effective_allowed_host_groups
    super
  end

end