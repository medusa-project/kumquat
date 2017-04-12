require 'csv'

class ItemTsvUpdater

  @@logger = CustomLogger.instance

  ##
  # Ingests items from the given TSV file.
  #
  # @param pathname [String] Absolute pathname of a TSV file.
  # @param original_filename [String] Filename of the TSV file as it was
  #                                   submitted to the application.
  # @param task [Task] Supply to receive progress updates.
  # @return [Integer] Number of items created or updated.
  #
  def ingest_pathname(pathname, original_filename = nil, task = nil)
    pathname = File.expand_path(pathname)
    filename = original_filename || File.basename(pathname)
    num_rows = File.read(pathname).scan(/\n/).count

    if task
      task.update(status_text: "Importing metadata for #{num_rows} items "\
      "from TSV (#{filename})")
    end
    @@logger.info("ItemTsvUpdater.ingest_pathname(): "\
        "ingesting metadata for #{num_rows} items from #{pathname}...")

    num_ingested = 0
    ActiveRecord::Base.transaction do
      # Treat the zero-byte as the quote character in order to allow quotes in
      # values without escaping.
      row_num = 0
      CSV.foreach(pathname, headers: true, col_sep: "\t",
                  quote_char: "\x00") do |tsv_row|
        progress = progress(row_num, num_rows)
        struct = tsv_row.to_hash
        item = Item.find_by_repository_id(struct['uuid'])
        if item
          @@logger.info("ItemTsvUpdater.ingest_pathname(): "\
              "#{struct['uuid']} #{progress}")
          item.update_from_tsv(struct)
          num_ingested += 1
        else
          @@logger.warn("ItemTsvUpdater.ingest_pathname(): "\
              "does not exist: #{struct['uuid']} #{progress}")
        end

        if task and row_num % 10 == 0
          task.update(percent_complete: row_num / num_rows.to_f)
        end

        row_num += 1
      end
    end
    num_ingested
  end

  private

  ##
  # @param row_num [Integer]
  # @param num_rows [Integer]
  # @return [String]
  #
  def progress(row_num, num_rows)
    percent = (((row_num + 1) / num_rows.to_f) * 100).round(2)
    "(#{row_num + 1}/#{num_rows}) (#{percent}%)"
  end

end
