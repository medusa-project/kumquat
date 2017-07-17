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
# cleaned up using the `dls:downloads:cleanup` rake task.
#
# # Attributes
#
# * created_at:       Managed by ActiveRecord.
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
    num_deleted = 0
    Download.all.each do |download|
      # Delete the instance if it is more than max_age_seconds old.
      if Time.now.to_i - download.updated_at.to_i > max_age_seconds
        download.destroy!
        num_deleted += 1
      end
    end
    CustomLogger.instance.info("Download.cleanup(): deleted #{num_deleted} "\
          "instances > #{max_age_seconds} seconds old.")
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
      CustomLogger.debug("Download.delete_file(): deleting #{self.pathname}")
      File.delete(self.pathname)
    end
  end

end
