##
# Represents a file download.
#
# This model is part of a system that can be used for downloads that may take
# a long time to prepare. A typical workflow is:
#
# 1. The user clicks a download button.
# 2. The responding controller creates a [Download] instance, invokes an
#    asynchronous task to prepare the file for download, and redirects to the
#    instance's URL.
# 3. The task associates the Download with a [Task]. (This enables progress
#    reporting.)
# 4. The task does its work, periodically updating the associated [Task]'s
#    `percent_complete` attribute to keep the user informed. When done, it
#    sets {filename} to the file's filename, and sets the [Task]'s status to
#    {Task::Status::SUCCEEDED}.
# 5. The user reloads the page (or it reloads automatically via XHR), sees a
#    download link, and follows it to download the file.
#
# Periodically, old Download records and their corresponding files should be
# cleaned up using the `dls:downloads:cleanup` rake task. This will mark them
# as expired and delete their corresponding files. Expired instances are kept
# around for record keeping.
#
# # Attributes
#
# * `created_at` Managed by ActiveRecord.
# * `expired`    When a download is expired, it is no longer usable and its
#                associated file is no longer available. Client code should
#                call {expire} rather than setting this directly.
# * `filename`   Filename of the file to be downloaded. ({url} can be used
#                instead.
# * `key`        Random alphanumeric "public ID." Should be hard to guess so
#                that someone can't access someone else's download.
# * `updated_at` Managed by ActiveRecord.
# * `url`        URL to redirect to rather than downloading a local file. Must
#                be publicly accessible.
#
class Download < ApplicationRecord

  LOGGER = CustomLogger.new(Download)
  DOWNLOADS_KEY_PREFIX = 'downloads/'

  belongs_to :task, inverse_of: :download, optional: true

  before_create :assign_key
  # Downloads shouldn't be destroyed, but just in case.
  after_destroy :delete_object

  # Instances will often be updated from inside transactions, outside of which
  # any updates would not be visible. So, we use a different database
  # connection, to which they won't propagate.
  establish_connection "#{Rails.env}_2".to_sym

  ##
  # @param max_age_seconds [Integer]
  # @return [void]
  #
  def self.cleanup(max_age_seconds)
    max_age_seconds = max_age_seconds.to_i
    num_expired = 0
    # Expire instances more than max_age_seconds old.
    Download.uncached do
      Download.
          where(expired: false).
          where('updated_at < ?', Time.at(Time.now.to_i - max_age_seconds)).find_each do |download|
        download.expire
        num_expired += 1
      end
    end
    LOGGER.info('cleanup(): expired %d instances > %d seconds old.',
                num_expired, max_age_seconds)
  end

  ##
  # Sets the instance's `expired` attribute to true and deletes its
  # corresponding file.
  #
  # @return [void]
  #
  def expire
    delete_object
    self.update!(expired: true)
  end

  ##
  # @return [String, nil]
  #
  def object_key
    self.filename.present? ? DOWNLOADS_KEY_PREFIX + self.filename : nil
  end

  ##
  # @return [Boolean]
  #
  def ready?
    (self.filename || self.url) && self.task&.succeeded?
  end

  ##
  # @return [String] The key.
  #
  def to_param
    self.key
  end


  private

  def assign_key
    self.key = SecureRandom.hex
  end

  def delete_object
    if self.filename.present?
      LOGGER.debug('delete_object(): deleting %s', self.object_key)
      KumquatS3Client.instance.delete_object(bucket: KumquatS3Client::BUCKET,
                                             key: self.object_key)
    end
  end

end
