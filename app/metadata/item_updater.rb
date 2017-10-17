##
# Batch-updates item metadata.
#
class ItemUpdater

  @@logger = CustomLogger.instance

  ##
  # @param items [Enumerable<Item>]
  # @param element_name [String] Element to replace.
  # @param replace_values [Enumerable<Hash<Symbol,String>] Enumerable of hashes
  #                                                        with `:string` and
  #                                                        `:uri` keys.
  # @param task [Task] Supply to receive progress updates.
  # @return [void]
  #
  def change_element_values(items, element_name, replace_values, task = nil)
    ActiveRecord::Base.transaction do
      items.each_with_index do |item, index|
        item.elements.where(name: element_name).destroy_all
        replace_values.each do |hash|
          hash = hash.symbolize_keys
          item.elements.build(name: element_name,
                              value: hash[:string],
                              uri: hash[:uri])
        end
        item.save!

        if task and index % 10 == 0
          task.update(percent_complete: index / items.length.to_f)
        end
      end
    end
  end

  ##
  # Migrates all instances of the given source element to the given
  # destination element on all given items.
  #
  # @param items [Enumerable<Item>]
  # @param source_element [String] Element name.
  # @param dest_element [String] Element name.
  # @param task [Task] Supply to receive progress updates.
  # @return [void]
  #
  def migrate_elements(items, source_element, dest_element, task = nil)
    ActiveRecord::Base.transaction do
      items.each_with_index do |item, index|
        @@logger.info("ItemUpdater.migrate_mlements(): migrating "\
            "#{source_element} to #{dest_element} in #{item}")
        item.migrate_elements(source_element, dest_element)

        if task and index % 10 == 0
          task.update(percent_complete: index / items.length.to_f)
        end
      end
    end
  end

  ##
  # @param items [Enumerable<Item>]
  # @param matching_mode [Symbol] :exact_match, :contain, :start, or :end
  # @param find_value [String] Value to search for.
  # @param element_name [String] Element in which to search.
  # @param replace_mode [Symbol] What part of the matches to replace:
  #                              :whole_value or :matched_part
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

    ActiveRecord::Base.transaction do
      items.each_with_index do |item, index|
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

          if task and index % 10 == 0
            task.update(percent_complete: index / items.length.to_f)
          end
        end
      end
    end
  end

end
