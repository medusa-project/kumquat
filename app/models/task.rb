##
# A representation of a task (typically but not necessarily a Job) for
# displaying  to an end user.
#
# To use:
#     task = Task.create!(name: 'Do Something',
#                         status_text: 'Doing something')
#     # do stuff...
#
#     task.progress = 0.3
#
#     # do some more stuff...
#
#     task.status_text = 'Wrapping up'
#     task.progress = 0.9
#
#     # done
#     task.done
#
class Task < ActiveRecord::Base

  ##
  # Enum-like class.
  #
  class Status

    WAITING = 0
    RUNNING = 1
    PAUSED = 2
    SUCCEEDED = 3
    FAILED = 4

    ##
    # @param status One of the Status constants
    # @return Human-readable status
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
  # connection, to which they won't propagate.
  establish_connection "#{Rails.env}_2".to_sym

  after_initialize :init
  before_save :constrain_progress, :auto_complete

  def init
    self.status ||= Status::WAITING
  end

  def done
    self.status = Status::SUCCEEDED
    self.save!
  end

  alias_method :succeeded, :done

  def progress=(float)
    self.percent_complete = float.to_f
    self.save!
  end

  def status=(status)
    if self.status != status and status == Status::RUNNING
      self.started_at = Time.now
    end

    write_attribute(:status, status)

    succeed if status == Status::SUCCEEDED
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
    self.completed_at = Time.now
    self.backtrace = nil
    self.detail = nil
  end

end
