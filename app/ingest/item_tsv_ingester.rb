require 'csv'

class ItemTsvIngester

  class ImportMode
    CREATE_AND_UPDATE = 'create_and_update'
    CREATE_ONLY = 'create_only'
  end

  ##
  # @param tsv [Array<Hash<String,String>>]
  # @return [Boolean] Whether the given TSV is DLS TSV. If not, it's probably
  #                   Medusa TSV.
  #
  def self.dls_tsv?(tsv)
    !tsv.first.keys.include?('inode_type')
  end

  ##
  # @param id [String] File/directory UUID
  # @return [String,nil] Directory UUID
  #
  def self.parent_directory_id(id, tsv)
    tsv.each do |row|
      if row['uuid'] == id
        return row['parent_directory_uuid'].present? ?
            row['parent_directory_uuid'] : nil
      end
    end
    nil
  end

  ##
  # Used only for items within the free-form content profile.
  #
  # @param item_id [String]
  # @param collection [Collection]
  # @param tsv [Hash<String,String>]
  # @return [Boolean] True if the given item ID is within the collection's
  #                   effective root CFS directory.
  #
  def self.within_root?(item_id, collection, tsv)
    effective_top_id = collection.effective_medusa_cfs_directory&.id
    if effective_top_id.present?
      next_parent_id = item_id
      while next_parent_id.present? do
        next_parent_id = parent_directory_id(next_parent_id, tsv)
        return true if next_parent_id == effective_top_id
      end
      return false
    end
    true
  end

  ##
  # Ingests items from the given TSV file.
  #
  # @param pathname [String] Absolute pathname of a TSV file
  # @param collection [Collection] Collection to ingest the items into.
  # @param import_mode [String] One of the ImportMode constants
  # @return [Integer] Number of items created or updated
  #
  def ingest_pathname(pathname, collection, import_mode)
    pathname = File.expand_path(pathname)
    Rails.logger.info("Ingesting items in #{pathname}...")

    ingest_tsv(File.read(pathname), collection, import_mode)
  end

  ##
  # Creates or updates items from the given TSV string.
  #
  # @param tsv [String] TSV body string
  # @param collection [Collection] Collection to ingest the items into.
  # @param import_mode [String] One of the ImportMode constants
  # @return [Integer] Number of items created or updated
  # @raises [RuntimeError]
  #
  def ingest_tsv(tsv, collection, import_mode)
    raise 'No TSV content provided.' unless tsv.present?
    raise 'No collection provided.' unless collection
    raise 'Invalid import mode.' unless
        ImportMode.constants.map{ |c| c.to_s.downcase }.include?(import_mode)
    raise 'Collection does not have a content profile assigned.' unless
        collection.content_profile
    raise 'Collection does not have a metadata profile assigned.' unless
        collection.metadata_profile

    # Treat the zero-byte as the quote character in order to allow quotes in
    # values.
    tsv = CSV.parse(tsv, headers: true, col_sep: "\t", quote_char: "\x00").
        map{ |row| row.to_hash }
    count = 0
    ActiveRecord::Base.transaction do
      collection.content_profile.items_from_tsv(tsv).each do |row|
        unless self.class.within_root?(row['uuid'], collection, tsv)
          Rails.logger.info("Skipping #{row['uuid']} (outside of root)")
          next
        end

        item = Item.find_by_repository_id(row['uuid'])
        if item
          if import_mode != ImportMode::CREATE_ONLY
            Rails.logger.info("Updating #{row['uuid']}")
            item.collection = collection
            item.update_from_tsv(tsv, row)
            count += 1
          else
            Rails.logger.info("Skipping #{row['uuid']} "\
            "(already exists [create-only mode])")
          end
        else
          Rails.logger.info("Creating #{row['uuid']}")
          Item.from_tsv(tsv, row, collection)
          count += 1
        end
      end
    end
    count
  end

end
