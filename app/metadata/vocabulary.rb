##
# A vocabulary is a list of terms (values) that can be set as values of an
# ItemElement. This list may be controlled (curated/restricted) or uncontrolled
# (anything goes).
#
# ElementDefs need to be associated with one or more vocabularies. By default,
# new ElementDefs are associated with the uncontrolled vocabulary instance,
# which signifies that they may contain any value. The application depends on
# this instance (with a key of "uncontrolled") always existing.
#
class Vocabulary < ActiveRecord::Base

  has_and_belongs_to_many :element_defs
  has_many :vocabulary_terms, -> { order(:string, :uri) },
           inverse_of: :vocabulary, dependent: :destroy

  validates :key, presence: true, format: { with: /\A[-a-zA-Z0-9]+\Z/ },
            uniqueness: { case_sensitive: false }
  validates :name, presence: true, length: { maximum: 100 },
            uniqueness: { case_sensitive: false }

  before_update :restrict_uncontrolled_changes

  UNCONTROLLED_KEY = 'uncontrolled'

  ##
  # @param json [String] JSON string from as_json()
  # @return [Vocabulary] Persisted Vocabulary
  # @raises [ArgumentError] If a vocabulary with the same key or name already
  #                         exists.
  #
  def self.from_json(json)
    struct = JSON.parse(json)
    vocab = Vocabulary.new

    if Vocabulary.find_by_key(struct['key'])
      raise ArgumentError, 'A vocabulary with the same key already exists.'
    end
    if Vocabulary.find_by_name(struct['name'])
      raise ArgumentError, 'A vocabulary with the same name already exists.'
    end

    ActiveRecord::Base.transaction do
      vocab.key = struct['key']
      vocab.name = struct['name']

      # Add its terms.
      struct['vocabulary_terms'].each do |vt|
        term = vocab.vocabulary_terms.build
        term.string = vt['string']
        term.uri = vt['uri']
        term.save!
      end
      vocab.save!
    end
    vocab
  end

  ##
  # @return [Vocabulary] The uncontrolled vocabulary.
  #
  def self.uncontrolled
    Vocabulary.find_by_key(UNCONTROLLED_KEY)
  end

  ##
  # Overrides parent to serialize an instance to JSON with its child
  # vocabulary terms included.
  #
  # @param options [Hash]
  # @return [String]
  #
  def as_json(options = {})
    super(options.merge(include: :vocabulary_terms))
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
