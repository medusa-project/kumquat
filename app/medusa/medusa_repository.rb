##
# Represents a Medusa repository node.
#
# Instances' properties are loaded from Medusa automatically and cached.
# Acquire instances with {with_medusa_database_id}. Reload an existing instance
# with {load_from_medusa}.
#
class MedusaRepository < ApplicationRecord

  LOGGER = CustomLogger.new(MedusaRepository)

  ##
  # @param id [Integer]
  # @return [MedusaRepository]
  #
  def self.with_medusa_database_id(id)
    repo = MedusaRepository.find_by_medusa_database_id(id)
    unless repo
      repo = MedusaRepository.new(medusa_database_id: id)
      repo.load_from_medusa
      repo.save!
    end
    repo
  end

  ##
  # Downloads and caches the instance's Medusa representation and populates
  # the instance with it.
  #
  # @return [void]
  #
  def load_from_medusa
    raise 'load_from_medusa() called without ID set' unless
        self.medusa_database_id.present?

    client = MedusaClient.instance
    response = client.get(self.url + '.json')

    if response.status < 300
      LOGGER.debug('load_from_medusa(): loading %s', self.url)
      struct                 = JSON.parse(response.body)
      self.contact_email     = struct['contact_email']
      self.email             = struct['email']
      self.title             = struct['title']
      self.ldap_admin_domain = struct['ldap_admin_domain']
      self.ldap_admin_group  = struct['ldap_admin_group']
    end
  end

  ##
  # @return [String] Absolute URI of the Medusa repository resource, or nil
  #                  if the instance does not have an ID.
  #
  def url
    if self.medusa_database_id
      return Configuration.instance.medusa_url.chomp('/') +
          '/repositories/' + self.medusa_database_id.to_s
    end
    nil
  end

end
