##
# Represents a file download.
#
# This model is part of a system that can be used for downloads that will take
# a long time to prepare. A typical workflow is:
#
# 1. The user clicks a download button.
# 2. The responding controller creates a Download instance, invokes an
#    asynchronous ActiveJob to prepare the file for download, and redirects to
#    the download instance's URL.
# 3. The job associates the Download with a Task. (This enables progress
#    tracking.)
# 4. The job does its work, periodically updating the associated Task's
#    `percent_complete` attribute to keep the user informed. When done, it
#    sets `filename` to the file's filename, and sets the Task's status to
#    `Task::Status::SUCCEEDED`.
# 5. The user reloads the page (or it reloads automatically via AJAX), sees a
#    download link, and follows it to download the file.
#
# Periodically, old Download records and their corresponding files should be
# cleaned up using the `dls:downloads:cleanup` rake task. This will mark them
# as expired and delete their corresponding files. Expired instances are kept
# around for record-keeping.
#
# # Attributes
#
# * created_at:       Managed by ActiveRecord.
# * expired:          When a download is expired, it is no longer usable and
#                     its associated file is no longer available. Client code
#                     should call expire() rather than setting this directly.
# * filename:         Filename of the file to be downloaded. (`url` can be
#                     used instead.
# * key:              Random alphanumeric "public ID." Should be hard to guess
#                     so that someone can't retrieve someone else's download.
# * updated_at:       Managed by ActiveRecord.
# * url:              URL to redirect to rather than downloading a local file.
#                     Must be publicly accessible.
#
class Download < ActiveRecord::Base

  belongs_to :task, inverse_of: :download

  before_create :assign_key
  # Downloads shouldn't be destroyed, but just in case.
  after_destroy :delete_file

  DOWNLOADS_DIRECTORY = File.join(Rails.root, 'tmp', 'downloads')

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
    Download.all.each do |download|
      # Expire the instance if it is more than max_age_seconds old.
      if Time.now.to_i - download.updated_at.to_i > max_age_seconds
        download.expire
        num_expired += 1
      end
    end
    CustomLogger.instance.info("Download.cleanup(): expired #{num_expired} "\
          "instances > #{max_age_seconds} seconds old.")
  end

  ##
  # Sets the instance's `expired` attribute to true and deletes its
  # corresponding file.
  #
  # @return [void]
  #
  def expire
    delete_file
    self.update!(expired: true)
  end

  ##
  # @return [String, nil]
  #
  def pathname
    self.filename.present? ? File.join(DOWNLOADS_DIRECTORY, self.filename) : nil
  end

  ##
  # @return [Boolean]
  #
  def ready?
    self.task and self.task.status == Task::Status::SUCCEEDED
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

  def delete_file
    if self.filename.present? and File.exists?(self.pathname)
      CustomLogger.instance.debug("Download.delete_file(): deleting #{self.pathname}")
      File.delete(self.pathname)
    end
  end

end
