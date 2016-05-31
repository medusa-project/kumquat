require 'csv'

class ItemTsvIngester

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
  #
  def ingest_tsv(tsv, collection, task = nil)
    raise 'No TSV content provided.' unless tsv.present?
    raise 'No collection provided.' unless collection

    tsv = CSV.parse(tsv, headers: true, col_sep: "\t").map{ |row| row.to_hash }
    total_count = tsv.length
    count = 0
    ActiveRecord::Base.transaction do
      tsv.each do |row|
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
