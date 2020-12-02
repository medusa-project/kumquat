require 'test_helper'

class CreateZipOfJpegsJobTest < ActiveSupport::TestCase

  setup do
    @download = Download.create
  end

  teardown do
    File.delete(@download.pathname) if @download.pathname rescue nil
  end

  # perform()

  test 'perform() assembles the expected zip file' do
    items = [items(:free_form_dir1_dir1_file1).repository_id]
    CreateZipOfJpegsJob.perform_now(items, 'items', false, @download)
    Dir.mktmpdir do |tmpdir|
      `unzip "#{@download.pathname}" -d #{tmpdir}`
      assert Dir.glob("#{tmpdir}/*").length > 0
    end
  end

  test 'perform() updates the download object' do
    items = [items(:free_form_dir1_dir1_file1).repository_id]
    CreateZipOfJpegsJob.perform_now(items, 'items', false, @download)
    assert_equal Task::Status::SUCCEEDED, @download.task.status
    assert File.exists?(@download.pathname)
  end

end
