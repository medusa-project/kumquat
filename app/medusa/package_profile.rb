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
          name: 'Compound Object'
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
  # @return [Enumerable<PackageProfile>]
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

  COMPOUND_OBJECT_PROFILE = PackageProfile.find(1)
  FREE_FORM_PROFILE = PackageProfile.find(0)
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
        return MedusaFreeFormIngester.parent_id_from_medusa(item_id)
      when 1
        return compound_parent_id_from_medusa(item_id)
    end
    nil
  end

  private

  ##
  # @param item_id [String]
  # @return [String]
  #
  def compound_parent_id_from_medusa(item_id) # TODO: move this
    client = Medusa.client
    json = client.get(Medusa.url(item_id), follow_redirect: true).body
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
      json = client.get(Medusa.url(struct['directory']['uuid']),
                        follow_redirect: true).body
      struct2 = JSON.parse(json)
      return struct2['parent_directory']['uuid']
    end
  end

end