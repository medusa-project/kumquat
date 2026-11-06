## 
# Encapsulates an item event, representing actions taken when an admin user makes a change to Metadata in the DL system. 
# An event is attached to an item and a user.
#
class ItemEvent < ApplicationRecord

  belongs_to :item
  belongs_to :user

  def change_summary
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

    actions.empty? ? event_type.humanize : actions.uniq.join('; ')
  end

end
