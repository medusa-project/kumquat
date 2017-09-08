require 'test_helper'

class JobTest < ActiveSupport::TestCase

  test 'worker_pids() returns an enumerable of integers' do
    # There are no worker pid files when testing, so create some fake ones.
    pidfiles = [
        Job::WORKER_PIDS_PATH + '/delayed_job.1.pid',
        Job::WORKER_PIDS_PATH + '/delayed_job.2.pid'
    ]

    begin
      pidfiles.each_with_index do |pidfile, index|
        File.open(pidfile, 'w') do |contents|
          contents.write(index)
        end
      end

      assert_equal Set.new([0, 1]), Job.worker_pids
    ensure
      pidfiles.each do |file|
        File.delete(file)
      end
    end
  end

end
