##
# Represents a Medusa repository node.
#
# Instances' properties are loaded from Medusa automatically and cached.
# Acquire instances with `with_medusa_database_id()`.
#
class MedusaRepository < ActiveRecord::Base

  ##
  # @param id [Integer]
  # @return [MedusaRepository]
  #
  def self.with_medusa_database_id(id)
    repo = MedusaRepository.find_by_medusa_database_id(id)
    unless repo
      repo = MedusaRepository.new
      repo.medusa_database_id = id
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

    client = MedusaClient.new
    response = client.get(self.url + '.json')

    if response.status < 300
      CustomLogger.instance.debug('MedusaRepository.load_from_medusa(): loading ' + self.url)
      struct = JSON.parse(response.body)
      self.contact_email = struct['contact_email']
      self.email = struct['email']
      self.title = struct['title']
    end
  end

  ##
  # @return [String] Absolute URI of the Medusa repository resource, or nil
  # if the instance does not have an ID.
  #
  def url
    if self.medusa_database_id
      return Configuration.instance.medusa_url.chomp('/') +
          '/repositories/' + self.medusa_database_id.to_s
    end
    nil
  end

end
