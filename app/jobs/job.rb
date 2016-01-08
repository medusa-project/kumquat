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
  # object that includes GlobalID::Identifier.
  #
  def perform(*args)
    raise 'Must override perform()'
  end

  rescue_from(RuntimeError) do |e|
    self.task.status = Task::Status::FAILED
    self.task.save!
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

  def do_before_enqueue
  end

  def do_after_enqueue
    # background jobs will have a job_id, but foreground jobs will not, so use
    # the object_id instead.
    Task.create!(name: self.class.name, job_id: self.job_id || self.object_id,
                 status: Task::Status::WAITING)
  end

  def do_before_perform
    self.task.status = Task::Status::RUNNING
    self.task.save!
  end

  def do_after_perform
    self.task.status = Task::Status::SUCCEEDED
    self.task.save!
  end

end
