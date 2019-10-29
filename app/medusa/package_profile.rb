##
# Content in a Medusa file group is organized (in terms of its folder
# structure, naming scheme, etc.) according to a package profile. An instance
# of this class representing a given profile is associated with a [Collection]
# representing a Medusa collection.
#
# [Documentation of profiles](https://wiki.illinois.edu/wiki/display/LibraryDigitalPreservation/Digital+Library+Package+Profiles)
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
      },
      {
          id: 3,
          name: 'Mixed Media'
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

  # [Documentation](https://wiki.illinois.edu/wiki/display/LibraryDigitalPreservation/Compound-item+Object+Package)
  # [Documentation of Sheet Music Compound Object (a compatible
  # superset)](https://wiki.illinois.edu/wiki/display/LibraryDigitalPreservation/Sheet+Music+Compound+Object)
  COMPOUND_OBJECT_PROFILE    = PackageProfile.find(1)

  # [Documentation](https://wiki.illinois.edu/wiki/display/LibraryDigitalPreservation/Free-Form+Package)
  FREE_FORM_PROFILE          = PackageProfile.find(0)

  # [Documentation](https://wiki.illinois.edu/wiki/display/LibraryDigitalPreservation/Single-item+Object+Package)
  SINGLE_ITEM_OBJECT_PROFILE = PackageProfile.find(2)

  # [Documentation](https://wiki.illinois.edu/wiki/display/LibraryDigitalPreservation/Mixed-Media+Object+package)
  MIXED_MEDIA_PROFILE        = PackageProfile.find(3)

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
        return MedusaCompoundObjectIngester.parent_id_from_medusa(item_id)
      when 3
        return MedusaMixedMediaIngester.parent_id_from_medusa(item_id)
    end
    nil
  end

end