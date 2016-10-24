##
# Wraps ActiveJob::Base with actions on Tasks that enable the job to be
# monitored via ActiveRecord queries. Most application jobs should extend this.
#
class Job < ActiveJob::Base

  before_enqueue :do_before_enqueue
  after_enqueue :do_after_enqueue
  before_perform :do_before_perform
  after_perform :do_after_perform

  ##
  # The main job execution method. In this method, implementations should
  # update the status text and percent complete of the current task
  # frequently:
  #
  #     self.task.status_text = 'Doing something'
  #     self.task.percent_complete = 0.45
  #     self.task.save!
  #
  # @param args Arguments to pass to the job. Must be serializable or an
  #             object that includes GlobalID::Identifier.
  #
  def perform(*args)
    raise 'Must override perform()'
  end

  def perform_now(*args)
    # background jobs will have a job_id, but foreground jobs will not, so use
    # the object_id instead.
    create_task_for_job_id(self.object_id)
    super
  end

  rescue_from(Exception) do |e|
    if self.task
      self.task.status = Task::Status::FAILED
      self.task.detail = "#{e}"
      self.task.backtrace = e.backtrace
      self.task.save!
    end
    raise e
  end

  ##
  # @return [Task] Task associated with the job, created after enqueue.
  #
  def task
    @task = Task.find_by_job_id(self.job_id || self.object_id) unless @task
    @task
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
    create_task_for_job_id(self.job_id) # Background jobs will have a job_id.
  end

  def do_before_perform
    if self.task
      self.task.status = Task::Status::RUNNING
      self.task.save!
    end
  end

  def do_after_perform
    self.task.succeeded
  end

  private

  def create_task_for_job_id(job_id)
    @task = Task.create!(name: self.class.name, job_id: job_id)
  end

end
