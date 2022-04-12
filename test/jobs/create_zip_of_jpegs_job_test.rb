require 'test_helper'

class CreateZipOfJpegsJobTest < ActiveSupport::TestCase

  setup do
    @download = Download.create
  end

  teardown do
    @download.destroy!
  end

  # perform()

  test 'perform() assembles the expected zip file' do
    items = [items(:free_form_dir1_image).repository_id]
    CreateZipOfJpegsJob.perform_now(items, 'items', false, @download)

    Dir.mktmpdir do |tmpdir|
      zip_path = File.join(tmpdir, "file.zip")
      client   = KumquatS3Client.instance
      client.get_object(bucket:          KumquatS3Client::BUCKET,
                        key:             @download.object_key,
                        response_target: zip_path)

      `unzip "#{zip_path}" -d #{tmpdir}`
      assert Dir.glob("#{tmpdir}/*").length > 1
    end
  end

  test 'perform() updates the download object' do
    items = [items(:free_form_dir1_image).repository_id]
    CreateZipOfJpegsJob.perform_now(items, 'items', false, @download)

    assert_equal Task::Status::SUCCEEDED, @download.task.status
  end

end
