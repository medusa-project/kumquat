##
# Encapsulates the act of a user watching something.
#
# # Attributes
#
# * `collection_id`: Foreign key to {Collection}.
# * `created_at`:    Managed by ActiveRecord.
# * `email`:         Optional; used instead of an associated {User} if filled
#                    in.
# * `updated_at`:    Managed by ActiveRecord.
# * `user_id`:       Foreign key to {User}. Used only if `email` is blank.
#
class Watch < ApplicationRecord
  belongs_to :collection
  belongs_to :user, optional: true

  validates :email, presence: false, length: {maximum: 255},
            format: {with: StringUtils::EMAIL_REGEX},
            uniqueness: {case_sensitive: false},
            allow_blank: true

  validate :validate_watcher

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


  private

  ##
  # Ensures that when {email} is set, {user_id} is not set, and vice versa.
  #
  def validate_watcher
    if self.user_id.present? && self.email.present?
      errors.add(:base, "User and email cannot both be set")
    elsif self.user_id.blank? && self.email.blank?
      errors.add(:base, "User or email must be set")
    end
  end

end
