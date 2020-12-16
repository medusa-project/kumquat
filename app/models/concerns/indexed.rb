##
# Concern to be included by models that get indexed in Elasticsearch. Provides
# almost all of the functionality they need except for {as_indexed_json}, which
# must be overridden.
#
# # Querying
#
# A low-level interface to Elasticsearch is provided by {ElasticsearchClient},
# but in most cases, it's better to use the higher-level query interface
# provided by the various {AbstractRelation} subclasses, which are easier to
# use, and take public accessibility etc. into account.
#
# # Persistence Callbacks
#
# **IMPORTANT NOTE**: Instances are automatically indexed in Elasticsearch (see
# {as_indexed_json}) upon transaction commit. They are **not** indexed on
# save or destroy. Whenever creating, updating, or deleting outside of a
# transaction, you must {reindex reindex} or {delete_document delete} the
# document manually.
#
module Indexed
  extend ActiveSupport::Concern

  class_methods do
    ##
    # Normally this method should not be used except to delete "orphaned"
    # documents with no database counterpart. See the module documentation for
    # information about correct document deletion.
    #
    def delete_document(id)
      query = {
        query: {
          bool: {
            filter: [
              {
                term: {
                  ElasticsearchIndex::StandardFields::ID => id
                }
              }
            ]
          }
        }
      }
      ElasticsearchClient.instance.delete_by_query(JSON.generate(query))
    end

    ##
    # Iterates through all of the model's indexed documents and deletes any for
    # which no counterpart exists in the database.
    #
    def delete_orphaned_documents
      class_ = name.constantize

      # Get the document count.
      relation = search.limit(0)
      # TODO: this is hacky - we need a general way to obtain a Relation with
      # no constraints
      if relation.respond_to?(:include_children_in_results)
        relation.include_children_in_results(true)
      end
      count    = relation.count
      progress = Progress.new(count)

      # Retrieve document IDs in batches.
      index = start = num_deleted = 0
      limit = 1000
      while start < count do
        ids = relation.start(start).limit(limit).to_id_a
        ids.each do |id|
          unless class_.exists?(id: id)
            class_.delete_document(id)
            num_deleted += 1
          end
          index += 1
          progress.report(index, "Deleting orphaned documents")
        end
        start += limit
      end
      puts "\nDeleted #{num_deleted} documents"
    end

    ##
    # Reindexes all of the class' indexed documents. Multi-threaded indexing is
    # supported to potentially make this go a lot faster, but care must be
    # taken not to overwhelm the Elasticsearch cluster.
    #
    # N.B. 1: Cursory testing suggests that benefit diminishes rapidly beyond 2
    # threads.
    #
    # N.B. 2: Orphaned documents are not deleted; for that, use
    # {delete_orphaned_documents}.
    #
    # @param es_index [String] Index name. If omitted, the default index is
    #                          used.
    # @param num_threads [Integer]
    # @return [void]
    #
    def reindex_all(es_index: nil, num_threads: 1)
      # THe basic idea is to divide the total number of results into num_threads
      # segments, and have each thread work on a segment.
      mutex              = Mutex.new
      threads            = Set.new
      num_records        = count
      progress           = Progress.new(num_records)
      record_index       = 0
      num_thread_records = (num_records / num_threads.to_f).ceil
      return if num_thread_records < 1

      num_threads.times do |thread_num|
        threads << Thread.new do
          batch_size  = [1000, num_thread_records].min
          num_batches = (num_thread_records / batch_size.to_f).ceil
          num_batches.times do |batch_index|
            batch_offset = batch_index * batch_size
            q_offset     = thread_num * num_thread_records + batch_offset
            q_limit      = [batch_size, num_thread_records - batch_offset].min
            uncached do
=begin
              puts "[num_records: #{num_records}] "\
                    "[num_threads: #{num_threads}] "\
                    "[thread_num: #{thread_num}] "\
                    "[num_thread_records: #{num_thread_records}] "\
                    "[batch_offset: #{batch_offset}] "\
                    "[batch_size: #{batch_size}] "\
                    "[offset: #{q_offset}] "\
                    "[limit: #{q_limit}] "
=end
              all.order(:id).offset(q_offset).limit(q_limit).each do |model|
                model.reindex(es_index)
                mutex.synchronize do
                  record_index += 1
                  progress.report(record_index,
                                  "Indexing #{name.downcase.pluralize}")
                end
              end
            end
          end
        end
      end
      threads.each(&:join)
      puts ""
    end

    ##
    # @return [AbstractRelation] Instance of one of the {AbstractRelation}
    #                            subclasses.
    #
    def search
      "#{name}Relation".constantize.new
    end

  end

  included do
    after_commit :reindex, on: [:create, :update]
    after_commit -> { self.class.delete_document(index_id) }, on: :destroy

    ##
    # @return [Hash] Indexable JSON representation of the instance. Does not
    #                need to include the model's ID.
    #
    def as_indexed_json
      raise 'Including classes must override as_indexed_json()'
    end

    ##
    # @return [String] ID of the instance's indexed document.
    #
    def index_id
      "#{self.class.name.downcase}:#{self.id}"
    end

    ##
    # @param index [String] Index name. If omitted, the default index is used.
    # @return [void]
    #
    def reindex(index = nil)
      index ||= Configuration.instance.elasticsearch_index
      ElasticsearchClient.instance.index_document(index,
                                                  self.index_id,
                                                  self.as_indexed_json)
    end
  end

end
