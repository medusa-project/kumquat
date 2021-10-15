class EnsureMetadataProfileElementVocabularyIsNotNull < ActiveRecord::Migration[6.1]
  def change
    result = exec_query("SELECT id FROM vocabularies WHERE key = 'uncontrolled'")
    if result.any?
      voc_id = result[0]['id']
      execute "INSERT INTO metadata_profile_elements_vocabularies(metadata_profile_element_id, vocabulary_id)
              SELECT mpe.id, #{voc_id}
              FROM metadata_profile_elements mpe
              LEFT JOIN metadata_profile_elements_vocabularies mpev ON mpe.id = mpev.metadata_profile_element_id
              WHERE mpev.vocabulary_id IS NULL;"
    end
  end
end
