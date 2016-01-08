namespace :peartree do

  desc 'Index a filesystem path'
  task :index, [:pathname] => :environment do |task, args|
    ReindexJob.perform_later(pathname: File.expand_path(args[:pathname]))
  end

end
