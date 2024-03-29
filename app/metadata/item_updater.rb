# frozen_string_literal: true

##
# Batch-updates item metadata.
#
class ItemUpdater

  LOGGER = CustomLogger.new(ItemUpdater)
  MAX_TSV_VALUE_LENGTH = 10000

  ##
  # @param items [ActiveRecord::Relation<Item>]
  # @param element_name [String] Element to replace.
  # @param replace_values [Enumerable<Hash<Symbol,String>>] Enumerable of hashes
  #                                                         with `:string` and
  #                                                         `:uri` keys.
  # @param task [Task] Supply to receive progress updates.
  # @return [void]
  #
  def change_element_values(items, element_name, replace_values, task = nil)
    Item.uncached do
      items.find_each.with_index do |item, index|
        Item.transaction do
          item.elements.where(name: element_name).destroy_all
          replace_values.each do |hash|
            hash = hash.symbolize_keys
            item.elements.build(name:  element_name,
                                value: hash[:string],
                                uri:   hash[:uri])
          end
          item.save!
        end
        if task && index % 10 == 0
          task.update(percent_complete: index / items.length.to_f)
        end
      end
    end
  end

  ##
  # Migrates all instances of the given source element to the given
  # destination element on all given items.
  #
  # @param items [ActiveRecord::Relation<Item>]
  # @param source_element [String] Element name.
  # @param dest_element [String] Element name.
  # @param task [Task] Supply to receive progress updates.
  # @return [void]
  #
  def migrate_elements(items, source_element, dest_element, task = nil)
    Item.uncached do
      items.find_each.with_index do |item, index|
        LOGGER.info('migrate_mlements(): migrating %s to %s in %s',
                    source_element, dest_element, item)
        item.migrate_elements(source_element, dest_element)

        if task && index % 10 == 0
          task.update(percent_complete: index / items.length.to_f)
        end
      end
    end
  end

  ##
  # @param items [ActiveRecord::Relation<Item>]
  # @param matching_mode [Symbol] `:exact_match`, `:contain`, `:start`, or
  #                               `:end`
  # @param find_value [String] Value to search for.
  # @param element_name [String] Element in which to search.
  # @param replace_mode [Symbol] What part of the matches to replace:
  #                              `:whole_value` or `:matched_part`
  # @param replace_value [String] Value to replace the matches with.
  # @param task [Task] Supply to receive progress updates.
  # @return [void]
  # @raises [ArgumentError]
  #
  def replace_element_values(items, matching_mode, find_value, element_name,
                             replace_mode, replace_value, task = nil)
    unless [:whole_value, :matched_part].include?(replace_mode)
      raise ArgumentError, "Illegal replace mode: #{replace_mode}"
    end
    unless [:exact_match, :contain, :start, :end].include?(matching_mode)
      raise ArgumentError, "Illegal matching mode: #{matching_mode}"
    end

    items.find_each.with_index do |item, index|
      Item.transaction do
        item.elements.where(name: element_name).each do |element|
          case matching_mode
            when :exact_match
              if element.value == find_value
                element.value = replace_value
                element.save!
              end
            when :contain
              if element.value&.include?(find_value)
                case replace_mode
                  when :whole_value
                    element.value = replace_value
                  when :matched_part
                    element.value.gsub!(find_value, replace_value)
                end
                element.save!
              end
            when :start
              if element.value&.start_with?(find_value)
                case replace_mode
                  when :whole_value
                    element.value = replace_value
                  when :matched_part
                    element.value.gsub!(find_value, replace_value)
                end
                element.save!
              end
            when :end
              if element.value&.end_with?(find_value)
                case replace_mode
                  when :whole_value
                    element.value = replace_value
                  when :matched_part
                    element.value.gsub!(find_value, replace_value)
                end
                element.save!
              end
          end
          if task && index % 10 == 0
            task.update(percent_complete: index / items.length.to_f)
          end
        end
      end
    end
  end

  ##
  # @param collection [Collection]
  # @param include_date_created [Boolean]
  # @param task [Task]
  #
  def update_from_embedded_metadata(collection:,
                                    include_date_created: false,
                                    task:                 nil)
    items = collection.items
    count = items.count
    Item.uncached do
      items.find_each.with_index do |item, index|
        initial_title = item.title
        item.update_from_embedded_metadata(include_date_created: include_date_created)
        # If there is no title present in the new metadata, restore the initial
        # title.
        unless item.elements.find{ |e| e.name == 'title' }
          item.elements.build(name: 'title', value: initial_title).save!
        end
        if task && index % 10 == 0
          task.update(status_text:      "Updating #{count} items from embedded metadata",
                      percent_complete: index / count.to_f)
        end
      end
      task&.succeeded
    end
  end

  ##
  # Updates items from the given TSV file.
  #
  # Items will not be created or deleted. (For that, use {MedusaIngester}.)
  #
  # @param pathname [String] Absolute pathname of a TSV file.
  # @param original_filename [String] Filename of the TSV file as it was
  #                                   submitted to the application.
  # @param task [Task] Supply to receive progress updates.
  # @return [Integer] Number of items updated.
  #
  def update_from_tsv(pathname, original_filename = nil, task = nil)
    pathname = File.expand_path(pathname)
    filename = original_filename || File.basename(pathname)
    num_rows = 0
    File.foreach(pathname) do
      num_rows += 1
    end
    status = "Importing metadata for #{num_rows} items from TSV (#{filename})"
    task&.update(status_text: status)
    LOGGER.info("update_from_tsv(): %s", status)

    num_ingested = 0
    row_num      = 0

    # Treat the zero byte as the quote character in order to allow quotes in
    # values without escaping.
    Item.uncached do
      CSV.foreach(pathname, headers: true, col_sep: "\t",
                  quote_char: "\x00") do |tsv_row|
        progress = progress(row_num, num_rows)
        struct   = tsv_row.to_hash
        item     = Item.find_by_repository_id(struct['uuid'])
        if item
          LOGGER.info('update_from_tsv(): %s %s',
                      struct['uuid'], progress)
          item.update_from_tsv(struct)
          num_ingested += 1
        else
          LOGGER.warn('update_from_tsv(): does not exist: %s %s',
                      struct['uuid'], progress)
        end

        if task && row_num % 10 == 0
          task.update(percent_complete: row_num / num_rows.to_f)
        end
        row_num += 1
      end
    end
    num_ingested
  end

  ##
  # Ensures that the given TSV file does not contain any columns that the given
  # metadata profile does not contain, and also that none of the columns are
  # using a vocabulary not defined in the corresponding metadata profile
  # element.
  #
  # @param pathname [String]
  # @param metadata_profile [MetadataProfile]
  # @raises [ArgumentError] if the TSV header is invalid.
  #
  def validate_tsv(pathname:, metadata_profile:)
    pathname = File.expand_path(pathname)
    CSV.foreach(pathname, headers: true, col_sep: "\t",
                quote_char: "\x00") do |tsv_row|
      header_row = tsv_row.to_hash
      validate_tsv_header(header_row:       header_row,
                          metadata_profile: metadata_profile)
      break
    end
    true
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

  ##
  # @param header_row [Hash] Deserialized TSV header row.
  # @param metadata_profile [MetadataProfile]
  # @raises [ArgumentError]
  #
  def validate_tsv_header(header_row:, metadata_profile:)
    header_row.each do |heading, raw_value|
      # Vocabulary columns will have a heading of "vocabKey:elementLabel",
      # except uncontrolled columns which will have a heading of just
      # "elementLabel".
      heading_parts = heading.to_s.split(':')
      element_label = heading_parts.last
      element_name  = metadata_profile.elements.
        find{ |e| e.label == element_label }&.name

      # Skip non-descriptive columns.
      next if Item::NON_DESCRIPTIVE_TSV_COLUMNS.include?(element_label)

      if element_name
        # Get the vocabulary based on the prefix in the column heading.
        if heading_parts.length > 1
          vocabulary = Vocabulary.find_by_key(heading_parts.first)
          unless vocabulary
            raise ArgumentError, "Column contains an unrecognized vocabulary "\
              "key: #{heading_parts.first}"
          end
        end
      else
        raise ArgumentError, "Column contains an element not present in the "\
          "metadata profile: #{element_label}"
      end
    end
  end

end
