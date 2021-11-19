require 'test_helper'

class DownloadsControllerTest < ActionDispatch::IntegrationTest

  setup do
    @instance = downloads(:one)
    src_pathname = File.join(Rails.root, 'docker', 'mockdusa', 'content',
                             'repositories', '1', 'collections', '1',
                             'file_groups', '1', 'root', 'dir1', 'image1.jpg')
    dest_key = Download::DOWNLOADS_KEY_PREFIX + @instance.filename
    KumquatS3Client.instance.put_object(bucket: KumquatS3Client::BUCKET,
                                        key:    dest_key,
                                        body:   src_pathname)
  end

  teardown do
    KumquatS3Client.instance.delete_objects(prefix: Download::DOWNLOADS_KEY_PREFIX)
  end

  # file()

  test 'file() returns HTTP 404 for an invalid download key' do
    get download_file_path('bogus_key')
    assert_response :not_found
  end

  test 'file() returns HTTP 410 for an expired instance' do
    @instance.update!(expired: true)
    get download_file_path(@instance)
    assert_response :gone
  end

  test 'file() returns HTTP 403 when request IP address is different from the
  Download instance IP address' do
    @instance.update!(ip_address: '10.2.5.3')
    get download_file_path(@instance)
    assert_response :forbidden
  end

  test 'file() redirects to a pre-signed S3 URL upon success' do
    get download_file_path(@instance)
    assert_response :see_other
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

  test 'show() returns HTTP 200 for HTML' do
    get download_path(@instance)
    assert_response :ok
  end

  test 'show() returns HTTP 200 for XHR' do
    get download_path(@instance), xhr: true
    assert_response :ok
  end

  test 'show() returns HTTP 200 for JSON' do
    get download_path(@instance, format: :json)
    assert_response :ok
  end

end
