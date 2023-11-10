namespace :tasks do

  desc 'Clear all tasks'
  task :clear => :environment do
    Task.destroy_all
  end

  desc 'Clear running tasks'
  task :clear_running => :environment do
    Task.where(status: Task::Status::RUNNING).destroy_all
  end

  desc 'Clear waiting tasks'
  task :clear_waiting => :environment do
    Task.where(status: Task::Status::WAITING).destroy_all
  end

  desc 'Fail running tasks'
  task :fail_running => :environment do
    Task.where(status: Task::Status::RUNNING).each(&:fail)
  end

  desc 'Run a test task'
  task :test => :environment do
    SleepJob.new(interval: 15).perform_in_foreground
  end

end
