##
# Augments {ActiveJob::Base} with {Task} management functionality that enables
# the job to be monitored via ActiveRecord queries. Most application jobs
# should extend this.
#
class ApplicationJob < ActiveJob::Base

  class Queue
    ADMIN    = :admin
    PUBLIC   = :public

    def self.all
      self.constants.map{ |c| self.const_get(c) }
    end
  end

  before_enqueue :do_before_enqueue
  after_enqueue :do_after_enqueue
  before_perform :do_before_perform
  after_perform :do_after_perform

  ##
  # The main job execution method. In this method, implementations should
  # update the status text and percent complete of the current task
  # frequently:
  #
  # ```
  # self.task.update(status_text: 'Doing something',
  #                  percent_complete: 0.45)
  # ```
  #
  # @param args Arguments to pass to the job. Must be serializable or an
  #             instance of a class that `include`s [GlobalID::Identifier].
  #
  def perform(**args)
    raise 'Must override perform()'
  end

  ##
  # This is not a [ActiveJob::Job] method. Client code will call this instead
  # of {perform_now} so that the job can better discern whether it is being run
  # in the foreground.
  #
  def perform_in_foreground(**args)
    # Background jobs will have a job_id, but foreground jobs will not, so use
    # the object_id instead.
    create_task(job_id: self.object_id, user: args[:user])
    begin
      perform_now
    rescue Exception => e
      fail_task(e)
      raise e
    end
  end

  rescue_from(Exception) do |e|
    fail_task(e)
    if Rails.env.demo? || Rails.env.production?
      message = KumquatMailer.error_body(e)
      KumquatMailer.error(message).deliver_now
    end
    raise e
  end

  ##
  # @return [Task] Task associated with the job, created after enqueue.
  #
  def task
    unless Task.find_by_job_id(self.job_id)
      user = arguments.any? ? arguments[0][:user] : nil
      create_task(job_id: self.job_id, user: user)
    end
    Task.find_by_job_id(self.job_id)
  end


  protected

  ##
  # Will be called before enqueueing (background jobs only).
  #
  def do_before_enqueue
  end

  ##
  # Will be called after enqueueing (background jobs only).
  #
  def do_after_enqueue
    create_task(job_id: self.job_id, user: arguments.dig(0, :user))
  end

  def do_before_perform
    self.task&.update!(status: Task::Status::RUNNING)
  end

  def do_after_perform
    self.task&.succeeded
  end


  private

  def create_task(job_id:, user: nil)
    begin
      Task.create!(name:        self.class.name,
                   user:        user,
                   status_text: "Waiting for other tasks to finish...",
                   job_id:      job_id,
                   queue:       self.class::QUEUE)
    rescue ActiveRecord::RecordNotUnique
      # job_id is violating a uniqueness constraint. Assuming that job_id is a
      # UUID, this can only mean that a Task corresponding to this job has
      # already been created due to the ActiveJob engine having called its
      # after_enqueue callback(s) (and therefore this method) multiple times,
      # which is probably a bug, but one that can be worked around by rescuing
      # this.
    end
  end

  ##
  # @param e [Exception]
  #
  def fail_task(e)
    self.task&.update!(status:     Task::Status::FAILED,
                       stopped_at: Time.now,
                       detail:     "#{e}",
                       backtrace:  e.backtrace)
  end

end
