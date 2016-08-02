require 'csv'

class ItemTsvIngester

  ##
  # Ingests items from the given TSV file.
  #
  # @param pathname [String] Absolute pathname of a TSV file
  # @return [Integer] Number of items created or updated
  #
  def ingest_pathname(pathname)
    pathname = File.expand_path(pathname)
    Rails.logger.info("Ingesting items in #{pathname}...")

    ingest_tsv(File.read(pathname))
  end

  ##
  # Creates or updates items from the given TSV string.
  #
  # @param tsv [String] TSV body string
  # @return [Integer] Number of items created or updated
  # @raises [RuntimeError]
  #
  def ingest_tsv(tsv)
    raise 'No TSV content provided.' unless tsv.present?

    # Treat the zero-byte as the quote character in order to allow quotes in
    # values.
    tsv = CSV.parse(tsv, headers: true, col_sep: "\t", quote_char: "\x00").
        map{ |row| row.to_hash }
    count = 0
    ActiveRecord::Base.transaction do
      tsv.each do |row|
        item = Item.find_by_repository_id(row['uuid'])
        if item
          Rails.logger.info("Updating #{row['uuid']}")
          item.update_from_tsv(tsv, row)
          count += 1
        end
      end
    end
    count
  end

end
