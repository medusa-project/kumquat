##
# Term in a [Vocabulary].
#
# A term has two main properties: {string} and {uri}. (The latter is analogous
# to a Linked Data URI.)
#
# It can also be augmented with an image/icon and an "info URI" using the
# `vocabulary_term_info.yml` file. This is used for public display of certain
# terms, such as those in the RightsStatements.org and Creative Commons
# vocabularies, which have an accompanying icon and link to a rights page.
#
# # Attributes
#
# * `created_at`    Managed by ActiveRecord.
# * `string`        Term string value.
# * `updated_at`    Managed by ActiveRecord
# * `uri`           Term URI.
# * `vocabulary_id` Foreign key to the owning [Vocabulary].
#
class VocabularyTerm < ApplicationRecord

  AUGMENTED_INFO = YAML.unsafe_load_file(File.join(__dir__, 'vocabulary_term_info.yml'))

  belongs_to :vocabulary, inverse_of: :vocabulary_terms

  ##
  # @return [Enumerable<VocabularyTerm>]
  #
  def self.rights_related
    VocabularyTerm.where("uri IN (?)", AUGMENTED_INFO.map{ |l| l['uri'] }).order(:string)
  end

  ##
  # @return [String]
  #
  def image
    augmented_properties['image'] if augmented_properties
  end

  ##
  # @return [String]
  #
  def info_uri
    augmented_properties['info_uri'] if augmented_properties
  end

  ##
  # @return [String]
  #
  def to_s
    self.string || self.uri
  end


  private

  def augmented_properties
    @augmented_props = AUGMENTED_INFO.find{ |l| l['uri'] == self.uri } unless @augmented_props
    @augmented_props
  end

end
