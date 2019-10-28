##
# Representation of an asynchronous task for providing user status updates.
#
# To use:
#
# ```
# task = Task.create!(name: 'Do Something',
#                     status_text: 'Doing something')
# # do stuff...
#
# task.update(progress: 0.3)
#
# # do some more stuff...
#
# task.update(status_text: 'Wrapping up', progress: 0.9)
#
# # done
# task.done
# ```
#
class Task < ApplicationRecord

  ##
  # Enum-like class.
  #
  class Status

    WAITING   = 0
    RUNNING   = 1
    PAUSED    = 2
    SUCCEEDED = 3
    FAILED    = 4

    ##
    # @return [Enumerable<Integer>] All constant values.
    #
    def self.all
      (0..4)
    end

    ##
    # @param status [Integer] One of the Status constant values.
    # @return [String] Human-readable status.
    #
    def self.to_s(status)
      case status
        when Status::WAITING
          'Waiting'
        when Status::RUNNING
          'Running'
        when Status::PAUSED
          'Paused'
        when Status::SUCCEEDED
          'Succeeded'
        when Status::FAILED
          'Failed'
        else
          self.to_s
      end
    end

  end

  has_one :download, inverse_of: :task

  # Instances will often be updated from inside transactions, outside of which
  # any updates would not be visible. So, we use a different database
  # connection.
  establish_connection "#{Rails.env}_2".to_sym

  after_initialize :init
  before_save :constrain_progress, :auto_complete

  def init
    self.status ||= Status::WAITING
  end

  def done
    self.update!(status: Status::SUCCEEDED)
  end

  alias_method :succeeded, :done

  def fail
    self.update!(status: Status::FAILED)
  end

  def failed?
    self.status == Status::FAILED
  end

  def progress=(float)
    self.update!(percent_complete: float.to_f)
  end

  def status=(status)
    if self.status != status and status == Status::RUNNING
      self.started_at = Time.now
    end

    write_attribute(:status, status)

    succeed if status == Status::SUCCEEDED
  end

  def succeeded?
    self.status == Status::SUCCEEDED
  end

  private

  def auto_complete
    succeed if (1 - self.percent_complete).abs <= 0.0000001
  end

  def constrain_progress
    if self.percent_complete < 0
      self.percent_complete = 0
    elsif self.percent_complete > 1
      self.percent_complete = 1
    end
  end

  def succeed
    write_attribute(:status, Status::SUCCEEDED)
    self.percent_complete = 1
    self.completed_at     = Time.now
    self.backtrace        = nil
    self.detail           = nil
  end

end
