class VocabularyTerm < ActiveRecord::Base

  belongs_to :vocabulary, inverse_of: :vocabulary_terms

  validates_uniqueness_of :uri, scope: :vocabulary_id, allow_blank: true

  ##
  # @return [String]
  #
  def to_s
    self.string.present? ? "#{self.string}" : "#{self.uri}"
  end

end
