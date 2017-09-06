##
# Represents a Medusa file group.
#
# Instances' properties are loaded from Medusa automatically and cached.
# Acquire instances with `with_uuid()`.
#
class MedusaFileGroup < ApplicationRecord

  ##
  # @param uuid [String]
  # @return [MedusaCfsDirectory]
  #
  def self.with_uuid(uuid)
    fg = MedusaFileGroup.find_by_uuid(uuid)
    unless fg
      fg = MedusaFileGroup.new
      fg.uuid = uuid
      fg.load_from_medusa
      fg.save!
    end
    fg
  end

  ##
  # @return [MedusaCfsDirectory]
  #
  def cfs_directory
    if !@cfs_directory and self.cfs_directory_uuid.present?
      @cfs_directory = MedusaCfsDirectory.with_uuid(self.cfs_directory_uuid)
    end
    @cfs_directory
  end

  ##
  # Downloads and caches the instance's Medusa representation and populates
  # the instance with it.
  #
  # @return [void]
  #
  def load_from_medusa
    raise 'load_from_medusa() called without UUID set' unless self.uuid.present?

    client = MedusaClient.new
    response = client.get(self.url + '.json')

    if response.status < 300
      CustomLogger.instance.debug('MedusaFileGroup.load_from_medusa(): loading ' + self.url)
      struct = JSON.parse(response.body)
      if struct['cfs_directory']
        self.cfs_directory_uuid = struct['cfs_directory']['uuid']
      end
      self.title = struct['title']
    end
  end

  ##
  # @return [String] Absolute URI of the Medusa file group resource, or nil
  # if the instance does not have a UUID.
  #
  def url
    if self.uuid
      return Configuration.instance.medusa_url.chomp('/') +
          '/uuids/' + self.uuid.to_s
    end
    nil
  end

end
