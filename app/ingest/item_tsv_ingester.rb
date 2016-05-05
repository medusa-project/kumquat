require 'csv'

class ItemTsvIngester

  ##
  # Creates or updates items from the given XML document.
  #
  # @param tsv [String] TSV body string
  # @return [Integer] Number of items ingested
  #
  def ingest_tsv(tsv)
    # quote_char needs to be a character that the source data is guaranteed
    # not to contain: in this case, a unicode rocket ship.
    tsv = CSV.parse(tsv, headers: true, col_sep: "\t", quote_char: '🚀')
    count = 0
    tsv.each do |row|
      row_hash = row.to_hash
      puts row_hash
      item = Item.find_by_repository_id(row_hash['repositoryId'])
      if item
        item.update_from_tsv(row_hash)
      else
        Item.from_tsv(row_hash)
      end
      count += 1
    end
    count
  end

end
