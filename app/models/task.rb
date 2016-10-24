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

  # Instances will often be updated from inside transactions, outside of which
  # any updates would not be visible. So, we use a different database
  # connection, to which ActiveRecord::Base.transaction fortunately does not
  # propagate.
  establish_connection "#{Rails.env}_2".to_sym

  after_initialize :init
  before_save :constrain_progress, :auto_complete

  def init
    self.status ||= Status::RUNNING
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
    write_attribute(:status, status)
    if status == Status::SUCCEEDED
      self.percent_complete = 1
      self.completed_at = Time.now
    end
  end

  private

  def auto_complete
    if (1 - self.percent_complete).abs <= 0.0000001
      self.status = Status::SUCCEEDED
      self.completed_at = Time.now
    end
  end

  def constrain_progress
    if self.percent_complete < 0
      self.percent_complete = 0
    elsif self.percent_complete > 1
      self.percent_complete = 1
    end
  end

end
