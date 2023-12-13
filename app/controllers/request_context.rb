# frozen_string_literal: true

##
# Bundles information about a client request for authorization purposes.
#
class RequestContext

  ##
  # Client hostname.
  #
  # @return [String]
  #
  attr_accessor :client_hostname

  ##
  # Client IP address.
  #
  # @return [String]
  #
  attr_accessor :client_ip

  ##
  # @return [User] Client user. This will be `nil` in the case of a client who
  #                is not logged in.
  #
  attr_accessor :user

  ##
  # @param client_ip [String] The default value makes for more concise tests,
  #                           but a correct value should be provided for normal
  #                           use.
  # @param client_hostname [String] The default value makes for more concise
  #                                 tests, but a correct value should be
  #                                 provided for normal use.
  # @param user [User] The logged-in user, if one exists.
  #
  def initialize(client_ip:       "10.0.0.1",
                 client_hostname: "example.org",
                 user:            nil)
    self.client_ip       = client_ip
    self.client_hostname = client_hostname
    self.user            = user
  end

  ##
  # @return [Enumerable<HostGroup>]
  # 
  def client_host_groups
    HostGroup.all_matching_hostname_or_ip(@client_hostname, @client_ip)
  end

end
