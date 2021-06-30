##
# Encapsulates the act of a user watching something.
#
class Watch < ApplicationRecord
  belongs_to :collection
  belongs_to :user

  ##
  # For every watched collection, sends an email to all watching users
  # containing a list of all newly published (<= 24 hours) items in the
  # collection. If there are no such items, an email is not sent.
  #
  def self.send_new_item_emails
    watches  = Watch.all
    exporter = ItemTsvExporter.new
    progress = Progress.new(watches.count)
    watches.each_with_index do |watch, index|
      after  = 1.day.ago
      before = Time.now
      tsv    = exporter.items_in_collection(watch.collection,
                                            published_after:  after,
                                            published_before: before)
      # Only send the email if the TSV contains >= 1 item (>= 2 rows).
      if tsv.count(ItemTsvExporter::LINE_BREAK) > 1
        KumquatMailer.new_items(watch, tsv, after, before).deliver_now
      end
      progress.report(index + 1, 'Emailing watchers')
    end
  end

end
