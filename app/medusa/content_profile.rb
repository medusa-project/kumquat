##
# Content in a Medusa file group is organized (in terms of its folder
# structure, naming scheme, etc.) according to a content profile. An instance
# of this class representing a given profile is associated with a [Collection].
#
# Profiles can't be created by users. Their properties are hard-coded into a
# constant. An array of instances reflecting these properties can be accessed
# via `all()`.
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
  # @return [String, nil] UUID of the parent item of the given item, or nil
  #                       if there is no parent.
  # @raises [HTTPClient::BadResponseError]
  #
  def parent_id(item_id)
    case self.id
      when 0
        return parent_free_form_id(item_id)
      when 1
        return parent_map_id(item_id)
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

  def parent_free_form_id(item_id)
    client = Medusa.client
    json = client.get(medusa_url(item_id), follow_redirect: true).body
    struct = JSON.parse(json)
    if struct['parent_directory']
      json = client.get(medusa_url(struct['parent_directory']['uuid']),
                        follow_redirect: true).body
      struct2 = JSON.parse(json)
      unless struct2['parent_directory']
        return nil
      end
    elsif struct['directory']
      return struct['directory']['uuid']
    end
  end

  def parent_map_id(item_id)
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