##
# Encapsulates an Elasticsearch index.
#
# The application uses only one index. Its name is arbitrary. The application
# can be pointed directly at the index, or to an alias of the index, using the
# `elasticsearch_index` configuration key.
#
# # Index migration
#
# Elasticsearch index schemas can't (for the most part) be changed in place,
# so when a change is needed, a new index must be created. This involves
# modifying `app/search/index_schema.yml` and running the
# `elasticsearch:indexes:create` rake task.
#
# Once created, it must be populated with documents. If the documents in the
# old index are compatible with the new index, then this is a simple matter of
# running the `elasticsearch:indexes:reindex` rake task. Otherwise, all
# database entities need to be reindexed into the new index. This is more time-
# consuming and involves the `elasticsearch:items:reindex`,
# `elasticsearch:collections:reindex`, and `elasticsearch:agents:reindex` rake
# tasks.
#
# Once the new index has been populated, either the application's
# `elasticsearch_index` configuration key must be updated to point to it, or
# else the index alias that that key is pointing to must be changed to point to
# the new index.
#
class ElasticsearchIndex

  ##
  # Standard fields present in all documents.
  #
  class StandardFields
    CLASS               = 'sys_k_class'
    LAST_INDEXED        = 'sys_d_last_indexed'
    LAST_MODIFIED       = 'sys_d_last_modified'
    PUBLICLY_ACCESSIBLE = 'sys_b_publicly_accessible'
    SEARCH_ALL          = 'search_all'
  end

  SCHEMA = YAML.load_file(File.join(Rails.root, 'app', 'search', 'index_schema.yml'))

end