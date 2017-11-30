##
# Invokes a rake task.
#
# Use like: cap staging rake[kumquat:publish_collection,8132f520-e3fb-012f-c5b6-0019b9e633c5-f]
#
task :rake, [:command] => 'deploy:set_rails_env' do |task, args|
  on primary(:app) do
    within current_path do
      with :rails_env => fetch(:rails_env) do
        execute :rake, "#{args.command}[#{args.extras.join(',')}]"
      end
    end
  end
end