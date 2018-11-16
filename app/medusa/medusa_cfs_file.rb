##
# Represents a Medusa CFS file node.
#
# Instances' properties are loaded from Medusa automatically and cached.
# Acquire instances with `with_uuid()`.
#
class MedusaCfsFile < ApplicationRecord

  ##
  # @param uuid [String] Medusa UUID
  # @return [Boolean]
  #
  def self.file?(uuid)
    url = Configuration.instance.medusa_url.chomp('/') +
        '/uuids/' + uuid.to_s + '.json'
    # It's a file if Medusa redirects to a /cfs_files/ URI.
    client = MedusaClient.new
    response = client.head(url, follow_redirect: false)
    response.header['Location'].to_s.include?('/cfs_files/')
  end

  ##
  # @param uuid [String]
  # @return [MedusaCfsFile]
  #
  def self.with_uuid(uuid)
    file = MedusaCfsFile.find_by_uuid(uuid)
    unless file
      file = MedusaCfsFile.new
      file.uuid = uuid
      begin
        file.load_from_medusa
        file.save!
      rescue IOError => e
        CustomLogger.instance.warn("MedusaCfsFile.with_uuid(): #{e}", e)
      end
    end
    file
  end

  ##
  # @return [MedusaCfsDirectory]
  #
  def directory
    MedusaCfsDirectory.find_by_uuid(self.directory_uuid)
  end

  ##
  # Updates the instance with current properties from Medusa.
  #
  # @return [void]
  #
  def load_from_medusa
    raise 'load_from_medusa() called without UUID set' unless self.uuid.present?

    client = MedusaClient.new
    response = client.get(self.url + '.json')

    if response.status < 300
      CustomLogger.instance.debug('MedusaCfsFile.load_from_medusa(): loading ' + self.url)
      struct = JSON.parse(response.body)
      self.media_type = struct['content_type']
      self.repository_relative_pathname = "/#{struct['relative_pathname']}"
      if struct['directory'] and struct['directory']['uuid']
        self.directory_uuid = struct['directory']['uuid']
      else
        raise IOError, "Unexpected JSON structure: #{self.url} (does it exist?)"
      end
    end
  end

  ##
  # @return [String]
  #
  def name
    File.basename(self.pathname)
  end

  ##
  # @return [String]
  #
  def pathname
    self.repository_relative_pathname
  end

  ##
  # @param master_type [Binary::Type]
  # @param media_category [Binary::MediaCategory] If nil, will be inferred from
  #                                               the media type.
  # @return [Binary] Fully initialized binary instance. May be a new instance
  #                  or an existing one, but in any case, it may contain
  #                  changes that have not been persisted.
  #
  def to_binary(master_type, media_category = nil)
    p = '/' + self.repository_relative_pathname.reverse.chomp('/').reverse
    bin = Binary.find_by_repository_relative_pathname(p) || Binary.new
    bin.master_type = master_type
    bin.cfs_file_uuid = self.uuid
    bin.repository_relative_pathname = p
    # The type of the CFS file is likely to be vague, so let's see if we can do
    # better.
    bin.infer_media_type
    bin.media_category = media_category ||
        Binary::MediaCategory::media_category_for_media_type(bin.media_type)
    bin.read_characteristics
    bin
  end

  def to_s
    "#{self.uuid} #{self.repository_relative_pathname}"
  end

  ##
  # @return [String] Absolute URI of the Medusa CFS file resource, or nil if
  #                  the instance does not have a UUID.
  #
  def url
    url = nil
    if self.uuid
      url = Configuration.instance.medusa_url.chomp('/') +
          '/uuids/' + self.uuid.to_s.strip
    end
    url
  end

end
