## 
# Encapsulates an item event, representing actions taken when an admin user makes a change to Metadata in the DL system. 
# An event is attached to an item and a user.
#
class ItemEvent < ApplicationRecord

  belongs_to :item
  belongs_to :user

  before_validation :set_summary
  validates :summary, presence: true

  # Returns a human-readable summary of the changes made in this event, by either using the saved summary
  # or calculating it from the changeset with summary_for().
  def change_summary
    summary.presence || self.class.summary_for(changeset || {}, event_type)
  end

  # Calculates the before/after values and returns human readable text (ie 'Values reversed').
  def self.summary_for(changeset, event_type)
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

  private

  # Saves the calculated summary, running before validation. If the event's summary is blank
  # and event_type is present, it calls summary_for() to calculate the summary before saving it.
  def set_summary
    self.summary = self.class.summary_for(changeset || {}, event_type) if summary.blank? && event_type.present?
  end

end
