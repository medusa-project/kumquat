class AddSummaryToItemEvents < ActiveRecord::Migration[7.2]
  class EventRecord < ActiveRecord::Base
    self.table_name = 'item_events'
  end

  def up
    add_column :item_events, :summary, :string
    EventRecord.reset_column_information

    EventRecord.find_each do |event|
      event.update_columns(summary: summary_for(event.changeset || {}, event.event_type))
    end

    change_column_null :item_events, :summary, false
  end

  def down
    remove_column :item_events, :summary
  end

  private

  def summary_for(changeset, event_type)
    actions = changeset.values.flat_map do |change|
      before_groups = change.fetch('before', []).group_by { |entry| entry['vocabulary_id'] }
      after_groups = change.fetch('after', []).group_by { |entry| entry['vocabulary_id'] }

      (before_groups.keys | after_groups.keys).filter_map do |vocabulary_id|
        before_entries = before_groups.fetch(vocabulary_id, [])
        after_entries = after_groups.fetch(vocabulary_id, [])
        next if before_entries == after_entries

        if before_entries.reverse == after_entries
          'Values reversed'
        elsif before_entries.tally == after_entries.tally
          'Values reordered'
        else
          removed = before_entries.tally.any? do |entry, count|
            count > after_entries.count(entry)
          end
          added = after_entries.tally.any? do |entry, count|
            count > before_entries.count(entry)
          end

          if added && removed
            'Values edited'
          elsif added
            'Values added'
          else
            'Values removed'
          end
        end
      end
    end

    actions.empty? ? event_type.to_s.humanize : actions.uniq.join('; ')
  end
end
