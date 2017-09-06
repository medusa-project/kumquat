##
# N.B. Every instance must have a corresponding VocabularyTerm instance.
# These are auto-managed by ActiveRecord callbacks.
#
class AgentUri < ApplicationRecord

  belongs_to :agent, inverse_of: :agent_uris

  validates_presence_of :uri

  after_create :create_vocabulary_term
  after_update :update_vocabulary_term
  after_destroy :destroy_vocabulary_term

  ##
  # @return [String] The URI.
  #
  def to_s
    "#{self.uri}"
  end

  ##
  # @return [VocabularyTerm, nil] Vocabulary term corresponding to the
  #                               instance.
  #
  def vocabulary_term
    VocabularyTerm.find_by_uri(self.uri)
  end

  private

  def create_vocabulary_term
    new_vocabulary_term.save! unless vocabulary_term
  end

  def destroy_vocabulary_term
    vocabulary_term&.destroy!
  end

  def new_vocabulary_term
    VocabularyTerm.new(string: self.agent&.name, uri: self.uri,
                       vocabulary: Vocabulary::agent)
  end

  def update_vocabulary_term
    if self.uri_changed?
      old_uri = self.uri_was
      VocabularyTerm.find_by_uri(old_uri)&.destroy!
    end

    term = vocabulary_term
    if term
      term.update!(string: self.agent&.name, uri: self.uri)
    else
      new_vocabulary_term.save!
    end
  end

end
