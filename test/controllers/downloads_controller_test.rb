require 'test_helper'

class DownloadsControllerTest < ActionDispatch::IntegrationTest

  setup do
    @instance = downloads(:one)
    src = File.join(Rails.root, 'docker', 'mockdusa', 'content', 'repositories',
                    '1', 'collections', '1', 'file_groups', '1', 'root', 'dir1',
                    'image1.jpg')
    dest = File.join(Download::DOWNLOADS_DIRECTORY, @instance.filename)
    FileUtils.copy_file(src, dest)
  end

  teardown do
    FileUtils.rm_f(File.join(Download::DOWNLOADS_DIRECTORY, @instance.filename))
  end

  # file()

  test 'file() sends a file' do
    get download_file_path(@instance)
    assert_response :ok
  end

  test 'file() returns HTTP 404 for an invalid download key' do
    get download_file_path('bogus_key')
    assert_response :not_found
  end

  test 'file() returns HTTP 410 for an expired instance' do
    @instance.update!(expired: true)
    get download_file_path(@instance)
    assert_response :gone
  end

  # show()

  test 'show() returns HTTP 200 for an existing instance' do
    get download_path(@instance)
    assert_response :ok
  end

  test 'show() returns HTTP 404 for an invalid download key' do
    get download_path('bogus_key')
    assert_response :not_found
  end

  test 'show() returns HTTP 410 for an expired instance' do
    @instance.update!(expired: true)
    get download_path(@instance)
    assert_response :gone
  end

end
