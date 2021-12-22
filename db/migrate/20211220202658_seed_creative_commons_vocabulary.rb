class SeedCreativeCommonsVocabulary < ActiveRecord::Migration[6.1]
  def up
    # Create the vocabulary
    execute "INSERT INTO vocabularies(key, name, created_at, updated_at)
             VALUES ('cc', 'Creative Commons', NOW(), NOW())"
    # Get its ID
    id = execute("SELECT id FROM vocabularies ORDER BY created_at DESC LIMIT 1")[0]['id']
    # Add terms to it
    execute "INSERT INTO vocabulary_terms(string, uri, vocabulary_id, created_at, updated_at)
             VALUES
             ('Attribution 4.0', 'https://creativecommons.org/licenses/by/4.0/', #{id}, NOW(), NOW()),
             ('Attribution-ShareAlike 4.0', 'https://creativecommons.org/licenses/by-sa/4.0/', #{id}, NOW(), NOW()),
             ('Attribution-NonCommercial 4.0', 'https://creativecommons.org/licenses/by-nc/4.0/', #{id}, NOW(), NOW()),
             ('Attribution-NonCommercial-ShareAlike 4.0', 'https://creativecommons.org/licenses/by-nc-sa/4.0/', #{id}, NOW(), NOW()),
             ('Attribution-NoDerivatives 4.0', 'https://creativecommons.org/licenses/by-nd/4.0/', #{id}, NOW(), NOW()),
             ('Attribution-NonCommercial-NoDerivatives 4.0', 'https://creativecommons.org/licenses/by-nc-nd/4.0/', #{id}, NOW(), NOW()),
             ('CC0 1.0 Universal', 'https://creativecommons.org/publicdomain/zero/1.0/', #{id}, NOW(), NOW());"
  end

  def down
    id = execute("SELECT id FROM vocabularies WHERE key = 'cc';")[0]['id']
    execute "DELETE FROM vocabulary_terms WHERE id = #{id};"
    execute "DELETE FROM vocabularies WHERE id = #{id};"
  end
end
