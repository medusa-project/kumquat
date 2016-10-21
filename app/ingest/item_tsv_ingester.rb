require 'csv'

class ItemTsvIngester

  ##
  # Ingests items from the given TSV file.
  #
  # @param pathname [String] Absolute pathname of a TSV file
  # @return [Integer] Number of items created or updated
  # @raises [RuntimeError]
  #
  def ingest_pathname(pathname)
    pathname = File.expand_path(pathname)
    Rails.logger.info("ItemTsvIngester.ingest_pathname(): "\
        "ingesting from #{pathname}...")

    count = 0
    ActiveRecord::Base.transaction do
      # Treat the zero-byte as the quote character in order to allow quotes in
      # values without escaping.
      CSV.foreach(pathname, headers: true, col_sep: "\t",
                  quote_char: "\x00") do |tsv_row|
        struct = tsv_row.to_hash
        item = Item.find_by_repository_id(struct['uuid'])
        if item
          Rails.logger.info("ItemTsvIngester.ingest_pathname(): #{struct['uuid']}")
          item.update_from_tsv(struct)
          count += 1
        else
          Rails.logger.warn("ItemTsvIngester.ingest_pathname(): "\
              "does not exist: #{struct['uuid']}")
        end
      end
    end
    count
  end

end
