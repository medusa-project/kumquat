##
# Encapsulates an Elasticsearch index, which corresponds one-to-one with an
# Elasticsearch model, and has a particular schema.
#
# Note: the index-per-model approach is a legacy of the
# [elasticsearch-model gem](https://github.com/elastic/elasticsearch-rails/tree/master/elasticsearch-model)
# which is no longer being used. It would be better to have only one index.
#
# # Schemas
#
# Elasticsearch indexes can't be changed in place, so new ones have to be
# created with the desired changes.  Versioned index schemas are defined in
# `index_schemas.yml`. The version the application uses is set in
# `Option::Keys::CURRENT_INDEX_VERSION`. When the schema changes, the new
# indexes must be created and populated with documents, and then the
# application switched over to them. (Typically this is all done with rake
# tasks; see below.)
#
# ## Index migration
#
# 1. Define the new schemas in `index_schemas.yml`
# 2. `bin/rails elasticsearch:indexes:create_all_latest`
# 3. `bin/rails elasticsearch:indexes:populate_latest`
# 4. `bin/rails elasticsearch:indexes:migrate_to_latest`
# 5. Restart
#
# N.B.: The
# [elasticsearch-model gem](https://github.com/elastic/elasticsearch-rails/tree/master/elasticsearch-model)
# provides a DSL for defining a model's schema, but it works with constant
# index names, which is incompatible with the way the application migrates to
# new index versions. This class keeps all versions of all schema indexes for
# all models together in one place.
#
# @see: https://www.elastic.co/guide/en/elasticsearch/reference/current/indices-create-index.html
#
class ElasticsearchIndex

  LOGGER = CustomLogger.new(ElasticsearchIndex)

  # Prefixed to all index names used by the application.
  APPLICATION_INDEX_PREFIX  = 'dls'
  PUBLICLY_ACCESSIBLE_FIELD = 'b_publicly_accessible'
  SEARCH_ALL_FIELD          = 'search_all'

  ##
  # Array of definitions for all index schema versions. The array index is the
  # version.
  #
  SCHEMAS = YAML.load_file(File.join(Rails.root, 'app', 'search',
                                     'index_schemas.yml'))

  attr_accessor :name, :schema, :version

  ##
  # @param type [String] Type name.
  # @return [ElasticsearchIndex]
  #
  def self.current_index(type)
    build_index(type, current_index_version)
  end

  ##
  # @return [Integer]
  #
  def self.current_index_version
    Option::integer(Option::Keys::CURRENT_INDEX_VERSION) || 0
  end

  ##
  # @param type [String] Type name.
  # @return [ElasticsearchIndex]
  #
  def self.latest_index(type)
    build_index(type, latest_index_version)
  end

  ##
  # @return [Integer]
  #
  def self.latest_index_version
    SCHEMAS.length - 1
  end

  ##
  # @return [void]
  #
  def self.migrate_to_latest
    current_version = current_index_version
    latest_version  = latest_index_version

    if current_version < latest_version
      LOGGER.debug('migrate_to_latest(): [current version: %d] [latest version: %d]',
                   current_version, latest_version)
      Option.set(Option::Keys::CURRENT_INDEX_VERSION, latest_version)
      LOGGER.info('migrate_to_latest(): now using version %d', latest_version)
    else
      LOGGER.info('migrate_to_latest(): already on the latest version. Nothing to do.')
    end
  end

  ##
  # @return [void]
  #
  def self.rollback_to_previous
    current_version = current_index_version
    next_version = current_version - 1
    if next_version < 0
      raise 'Can\'t rollback past version 0'
    end
    LOGGER.info('rollback_to_previous(): [current version: %d] [next version: %d]',
                current_version, next_version)
    Option.set(Option::Keys::CURRENT_INDEX_VERSION, next_version)
    LOGGER.info('rollback_to_previous(): new version: %d', next_version)
  end

  ##
  # @return [Boolean]
  #
  def exists?
    ElasticsearchClient.instance.index_exists?(self.name)
  end

  def to_s
    self.name
  end

  private

  ##
  # @param type [String] Type name.
  # @param version [Integer] Schema version.
  # @return [ElasticsearchIndex]
  #
  def self.build_index(type, version)
    index = ElasticsearchIndex.new
    index.name = sprintf('%s_%d_%s_%s',
                         APPLICATION_INDEX_PREFIX,
                         version,
                         type.to_s.downcase.pluralize,
                         Rails.env)
    index.version = version
    index.schema = SCHEMAS[version][type.to_s.downcase]
    index
  end

end