require 'test_helper'

class DownloadTest < ActiveSupport::TestCase

  setup do
    @download = downloads(:one)
  end

  # cleanup()

  test 'cleanup() should work properly' do
    Download.destroy_all

    d1 = Download.create
    d2 = Download.create
    d3 = Download.create

    d1.update(updated_at: 25.hours.ago)

    Download.cleanup(60 * 60 * 24) # 1 day

    assert_equal 2, Download.count
  end

  # create()

  test 'key is assigned at creation' do
    assert @download.key.length > 20
  end

  # pathname()

  test 'pathname() should return the correct pathname' do
    assert_equal File.join(Rails.root, 'tmp', 'downloads', @download.filename),
                 @download.pathname
  end

  # ready?()

  test 'ready?() should return the correct value' do
    @download.task = Task.new(status: Task::Status::RUNNING)
    assert !@download.ready?
    @download.task.status = Task::Status::SUCCEEDED
    assert @download.ready?
  end

end
