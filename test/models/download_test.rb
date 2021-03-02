require 'test_helper'

class DownloadTest < ActiveSupport::TestCase

  setup do
    @download = downloads(:one)
  end

  # cleanup()

  test 'cleanup() works properly' do
    Download.destroy_all

    d1 = Download.create
    d2 = Download.create
    d3 = Download.create

    assert_equal 0, Download.where(expired: true).count

    d1.update(updated_at: 28.hours.ago)

    Download.cleanup(60 * 60 * 24) # 1 day

    assert_equal 1, Download.where(expired: true).count
  end

  # create()

  test 'key is assigned at creation' do
    assert @download.key.length > 20
  end

  # pathname()

  test 'pathname() returns the correct pathname' do
    assert_equal File.join(Rails.root, 'tmp', 'downloads', @download.filename),
                 @download.pathname
  end

  # ready?()

  test 'ready?() returns the correct value' do
    @download.task     = Task.new(status: Task::Status::RUNNING)
    @download.filename = "file.txt"
    assert !@download.ready?

    @download.task     = Task.new(status: Task::Status::SUCCEEDED)
    @download.filename = nil
    assert !@download.ready?

    @download.task.status = Task::Status::SUCCEEDED
    @download.filename    = "file.txt"
    assert @download.ready?
  end

end
