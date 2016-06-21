require 'csv'

class ItemTsvIngester

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
  # @param task [Task] Optional
  # @return [Integer] Number of items ingested
  #
  def ingest_pathname(pathname, collection, task = nil)
    pathname = File.expand_path(pathname)
    Rails.logger.info("Ingesting items in #{pathname}...")

    ingest_tsv(File.read(pathname), collection, task)
  end

  ##
  # Creates or updates items from the given TSV string.
  #
  # @param tsv [String] TSV body string
  # @param collection [Collection] Collection to ingest the items into.
  # @param task [Task] Optional
  # @return [Integer] Number of items ingested
  # @raises [RuntimeError]
  #
  def ingest_tsv(tsv, collection, task = nil)
    raise 'No TSV content provided.' unless tsv.present?
    raise 'No collection provided.' unless collection
    raise 'Collection does not have a content profile assigned.' unless
        collection.content_profile

    # Treat the zero-byte as the quote character in order to allow quotes in
    # values.
    tsv = CSV.parse(tsv, headers: true, col_sep: "\t", quote_char: "\x00").
        map{ |row| row.to_hash }
    total_count = tsv.length
    count = 0
    ActiveRecord::Base.transaction do
      collection.content_profile.items_from_tsv(tsv).each do |row|
        next unless self.class.within_root?(row['uuid'], collection, tsv)

        item = Item.find_by_repository_id(row['uuid'])
        if item
          item.collection = collection
          item.update_from_tsv(tsv, row)
        else
          Item.from_tsv(tsv, row, collection)
        end
        count += 1

        if task and count % 10 == 0
          task.progress = count / total_count.to_f
        end
      end
    end
    count
  end

end
