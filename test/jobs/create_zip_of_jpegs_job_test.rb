require 'test_helper'

class CreateZipOfJpegsJobTest < ActiveSupport::TestCase

  setup do
    @download = Download.create
  end

  teardown do
    File.delete(@download.pathname)
  end

  # perform()

  test 'perform() should assemble the expected zip file' do
    items = [items(:illini_union_dir1_file1).repository_id]
    CreateZipOfJpegsJob.perform_now(items, 'items', @download)
    Dir.mktmpdir do |tmpdir|
      `unzip #{@download.pathname} -d #{tmpdir}`
      assert Dir.glob("#{tmpdir}/*").length > 0
    end
  end

  test 'perform() should update the download object' do
    items = [items(:illini_union_dir1_file1).repository_id]
    CreateZipOfJpegsJob.perform_now(items, 'items', @download)
    assert_equal Download::Status::READY, @download.status
    assert File.exists?(@download.pathname)
  end

end
