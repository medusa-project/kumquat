##
# Content in a DLS-compatible Medusa file group is organized (in terms of its
# folder  structure, naming scheme, etc.) according to a content profile. An
# instance of this class representing a given profile is associated with a
# [Collection] representing a Medusa collection.
#
class ContentProfile

  # Note: constants for quickly accessing a particular profile are defined
  # further down.

  PROFILES = [
      {
          id: 0,
          name: 'Free-Form'
      },
      {
          id: 1,
          name: 'Map'
      }
  ]

  # @!attribute id
  #   @return [Integer]
  attr_accessor :id

  # @!attribute name
  #   @return [String]
  attr_accessor :name

  ##
  # @return [Array<ContentProfile>]
  #
  def self.all
    PROFILES.map do |profile|
      p = ContentProfile.new
      p.id = profile[:id]
      p.name = profile[:name]
      p
    end
  end

  def self.find(id)
    self.all.select{ |p| p.id == id.to_i }.first
  end

  FREE_FORM_PROFILE = ContentProfile.find(0)
  MAP_PROFILE = ContentProfile.find(1)

  ##
  # @param item_id [String]
  # @return [Array<Bytestream>]
  # @raises [HTTPClient::BadResponseError]
  #
  def bytestreams_for(item_id)
    case self.id
      when 0
        return free_form_bytestreams_for(item_id)
      when 1
        return map_bytestreams_for(item_id)
    end
    []
  end

  ##
  # @param item_id [String]
  # @return [String, nil] UUID of the parent item of the given item, or nil if
  #                       there is no parent.
  # @raises [HTTPClient::BadResponseError]
  #
  def parent_id(item_id)
    case self.id
      when 0
        return free_form_parent_id(item_id)
      when 1
        return map_parent_id(item_id)
    end
    nil
  end

  private

  ##
  # @param uuid [String]
  # @return [String] Absolute URI of the Medusa collection resource, or nil
  #                  if the instance does not have an ID.
  #
  def medusa_url(uuid)
    sprintf('%s/uuids/%s.json',
            PearTree::Application.peartree_config[:medusa_url].chomp('/'),
            uuid)
  end

  ##
  # In the free-form profile, there is one bytestream per file. Directories
  # have no bytestreams.
  #
  # @param item_id [String]
  # @return [Array<Bytestream>]
  #
  def free_form_bytestreams_for(item_id)
    bytestreams = []
    client = Medusa.client
    response = client.get(medusa_url(item_id), follow_redirect: true)
    if response.status < 300
      json = response.body
      struct = JSON.parse(json)
      if struct['mtime'] # Only files will have this key.
        bs = Bytestream.new
        bs.repository_relative_pathname =
            '/' + struct['relative_pathname'].reverse.chomp('/').reverse
        bs.bytestream_type = Bytestream::Type::PRESERVATION_MASTER
        bs.infer_media_type
        bytestreams << bs
      end
    end
    bytestreams
  end

  ##
  # @param item_id [String]
  # @return [String]
  #
  def free_form_parent_id(item_id)
    parent_id = nil
    client = Medusa.client
    response = client.get(medusa_url(item_id), follow_redirect: true)
    if response.status < 300
      json = response.body
      struct = JSON.parse(json)
      if struct['parent_directory']
        # Top-level items in a file group will have no parent_directory key,
        # so check one level up.
        json = client.get(medusa_url(struct['parent_directory']['uuid']),
                          follow_redirect: true).body
        struct2 = JSON.parse(json)
        if struct2['parent_directory']
          parent_id = struct['parent_directory']['uuid']
        end
      elsif struct['directory']
        parent_id = struct['directory']['uuid']
      end
    end
    parent_id
  end

  ##
  # Child items will reside in a directory called `access` or
  # `preservation`. These are the only items in this profile that will have
  # any associated bytestreams. Preservation and access filenames will be the
  # same, except preservation files will end in .tif and access filenames in
  # .jp2.
  #
  # @return [Array<Bytestream>]
  #
  def map_bytestreams_for(item_id)
    client = Medusa.client
    json = client.get(medusa_url(item_id), follow_redirect: true).body
    struct = JSON.parse(json)
    bytestreams = []

    if struct['directory']
      case struct['directory']['name']
        when 'preservation'
          # add the preservation master
          bs = Bytestream.new
          bs.bytestream_type = Bytestream::Type::PRESERVATION_MASTER
          bs.repository_relative_pathname =
              '/' + struct['relative_pathname'].reverse.chomp('/').reverse
          bs.infer_media_type
          bytestreams << bs

          # add the access master
          bs = Bytestream.new
          bs.bytestream_type = Bytestream::Type::ACCESS_MASTER
          bs.repository_relative_pathname =
              '/' + struct['relative_pathname'].reverse.chomp('/').reverse.
                  gsub('/preservation/', '/access/').chomp('.tif') + '.jp2'
          bs.infer_media_type
          bytestreams << bs
        when 'access'
          # add the preservation master
          bs = Bytestream.new
          bs.bytestream_type = Bytestream::Type::PRESERVATION_MASTER
          bs.repository_relative_pathname =
              '/' + struct['relative_pathname'].reverse.chomp('/').reverse.
                  gsub('/preservation/', '/access/').chomp('.jp2') + '.tif'
          bs.infer_media_type
          bytestreams << bs

          # add the access master
          bs = Bytestream.new
          bs.bytestream_type = Bytestream::Type::ACCESS_MASTER
          bs.repository_relative_pathname =
              '/' + struct['relative_pathname'].reverse.chomp('/').reverse
          bs.infer_media_type
          bytestreams << bs
      end

    end
    bytestreams
  end

  ##
  # @param item_id [String]
  # @return [String]
  #
  def map_parent_id(item_id)
    client = Medusa.client
    json = client.get(medusa_url(item_id), follow_redirect: true).body
    struct = JSON.parse(json)

    # Top-level items will have `access`, `metadata`, and/or `preservation`
    # subdirectories.
    if struct['subdirectories']&.
        select{ |n| %w(access metadata preservation).include?(n['name']) }&.any?
      return nil
      # Child items will reside in a directory called `access` or
      # `preservation`.
    elsif struct['directory'] and
        %w(access preservation).include?(struct['directory']['name'])
      json = client.get(medusa_url(struct['directory']['uuid']),
                        follow_redirect: true).body
      struct2 = JSON.parse(json)
      return struct2['parent_directory']['uuid']
    end
  end

end