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

end