require 'csv'

##
# Content in a Medusa file group is organized (in terms of its folder
# structure, naming scheme, etc.) according to a package profile. An instance
# of this class representing a given profile is associated with a [Collection]
# representing a Medusa collection.
#
class PackageProfile

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
      },
      {
          id: 2,
          name: 'Single-Item Object'
      }
  ]

  # @!attribute id
  #   @return [Integer]
  attr_accessor :id

  # @!attribute name
  #   @return [String]
  attr_accessor :name

  ##
  # @return [Array<PackageProfile>]
  #
  def self.all
    PROFILES.map do |profile|
      p = PackageProfile.new
      p.id = profile[:id]
      p.name = profile[:name]
      p
    end
  end

  def self.find(id)
    self.all.select{ |p| p.id == id.to_i }.first
  end

  FREE_FORM_PROFILE = PackageProfile.find(0)
  MAP_PROFILE = PackageProfile.find(1)
  SINGLE_ITEM_OBJECT_PROFILE = PackageProfile.find(2)

  def ==(obj)
    obj.kind_of?(self.class) and obj.id == self.id
  end

  ##
  # Queries Medusa to find the parent ID of the Item with the given ID.
  #
  # @param item_id [String]
  # @return [String, nil] UUID of the parent item of the given item, or nil if
  #                       there is no parent.
  # @raises [HTTPClient::BadResponseError]
  # @raises [ArgumentError] If the item ID is nil
  #
  def parent_id_from_medusa(item_id)
    raise ArgumentError, 'No ID provided' unless item_id
    case self.id
      when 0
        return free_form_parent_id_from_medusa(item_id)
      when 1
        return map_parent_id_from_medusa(item_id)
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
  # @param item_id [String]
  # @return [String]
  #
  def free_form_parent_id_from_medusa(item_id) # TODO: move this
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
  # @param item_id [String]
  # @return [String]
  #
  def map_parent_id_from_medusa(item_id) # TODO: move this
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