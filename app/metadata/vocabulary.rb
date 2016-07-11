##
# A vocabulary is a list of terms (values) that can be set as values of an
# Element. This list may be controlled (curated/restricted) or uncontrolled
# (anything goes).
#
# ElementDefs need to be associated with one or more vocabularies. By default,
# new ElementDefs are associated with the uncontrolled vocabulary instance,
# which signifies that they may contain any value. The application depends on
# this instance (with a key of "uncontrolled") always existing.
#
class Vocabulary < ActiveRecord::Base

  has_and_belongs_to_many :element_defs

  validates :key, presence: true, format: { with: /\A[-a-zA-Z0-9]+\Z/ },
            uniqueness: { case_sensitive: false }
  validates :name, presence: true, length: { maximum: 100 },
            uniqueness: { case_sensitive: false }

  before_update :restrict_uncontrolled_changes

  UNCONTROLLED_KEY = 'uncontrolled'

  ##
  # @return [Vocabulary] The uncontrolled vocabulary.
  #
  def self.uncontrolled
    Vocabulary.find_by_key(UNCONTROLLED_KEY)
  end

  ##
  # @return [Boolean] True if the instance is the uncontrolled instance.
  #
  def readonly?
    self.key == UNCONTROLLED_KEY
  end

  def to_s
    self.key
  end

  private

  def restrict_uncontrolled_changes
    self.key_was != UNCONTROLLED_KEY
  end

end
