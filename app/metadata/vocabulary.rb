class Vocabulary < ActiveRecord::Base

  has_and_belongs_to_many :element_defs

  validates :key, presence: true, format: { with: /\A[-a-zA-Z0-9]+\Z/ },
            uniqueness: { case_sensitive: false }
  validates :name, presence: true, length: { maximum: 100 },
            uniqueness: { case_sensitive: false }

  before_update :restrict_uncontrolled_changes

  ##
  # @return [Vocabulary] The uncontrolled vocabulary.
  #
  def self.uncontrolled
    Vocabulary.find_by_key('uncontrolled')
  end

  ##
  # @return [Boolean] True if the instance is the uncontrolled instance.
  #
  def readonly?
    self.key == 'uncontrolled'
  end

  private

  def restrict_uncontrolled_changes
    self.key_was != 'uncontrolled'
  end

end
