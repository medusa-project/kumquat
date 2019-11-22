require 'test_helper'

class ApplicationHelperTest < ActionView::TestCase

  # icon_for()

  test 'icon_for() works with class names' do
    assert icon_for(Agent).include?('fa-user-circle')
    assert icon_for(Collection).include?('fa-folder-open')
    assert icon_for(Item).include?('fa-cube')
    assert icon_for(User).include?('fa-user')
  end

  test 'icon_for() works with 3D items' do
    item = new_item
    item.representative_binary = three_d_binary
    assert icon_for(item).include?('fa-cube')
  end

  test 'icon_for() works with audio items' do
    item = new_item
    item.representative_binary = audio_binary
    assert icon_for(item).include?('fa-volume-up')
  end

  test 'icon_for() works with image items' do
    item = new_item
    item.representative_binary = image_binary
    assert icon_for(item).include?('fa-image')
  end

  test 'icon_for() works with document items' do
    item = new_item
    item.representative_binary = document_binary
    assert icon_for(item).include?('fa-file-pdf')
  end

  test 'icon_for() works with text items' do
    item = new_item
    item.representative_binary = text_binary
    assert icon_for(item).include?('fa-file-alt')
  end

  test 'icon_for() works with video items' do
    item = new_item
    item.representative_binary = video_binary
    assert icon_for(item).include?('fa-film')
  end

  test 'icon_for() works with directory-variant items' do
    item = items(:illini_union_dir1_dir1)
    assert icon_for(item).include?('fa-folder-open')
  end

  test 'icon_for() works with file-variant items' do
    item = items(:illini_union_dir1_dir1_file1)
    item.binaries.destroy_all
    assert icon_for(item).include?('fa-file')
  end

  test 'icon_for() works with compound objects' do
    item = items(:sanborn_obj1)
    assert icon_for(item).include?('fa-image')
  end

  # type_of()

  test 'type_of() works with class names' do
    assert_equal 'Agent', type_of(Agent)
    assert_equal 'Collection', type_of(Collection)
    assert_equal 'Item', type_of(Item)
    assert_equal 'User', type_of(User)
  end

  test 'type_of() works with 3D items' do
    item = new_item
    item.representative_binary = three_d_binary
    assert_equal '3D', type_of(item)
  end

  test 'type_of() works with audio items' do
    item = new_item
    item.representative_binary = audio_binary
    assert_equal 'Audio', type_of(item)
  end

  test 'type_of() works with image items' do
    item = new_item
    item.representative_binary = image_binary
    assert_equal 'Image', type_of(item)
  end

  test 'type_of() works with document items' do
    item = new_item
    item.representative_binary = document_binary
    assert_equal 'Document', type_of(item)
  end

  test 'type_of() works with text items' do
    item = new_item
    item.representative_binary = text_binary
    assert_equal 'Text', type_of(item)
  end

  test 'type_of() works with video items' do
    item = new_item
    item.representative_binary = video_binary
    assert_equal 'Video', type_of(item)
  end

  test 'type_of() works with directory-variant items' do
    item = items(:illini_union_dir1_dir1)
    assert_equal 'File Folder', type_of(item)
  end

  test 'type_of() works with file-variant items' do
    item = items(:illini_union_dir1_dir1_file1)
    item.binaries.destroy_all
    assert_equal 'File', type_of(item)
  end

  test 'type_of() works with compound objects' do
    item = items(:sanborn_obj1)
    assert_equal 'Multi-Page Item', type_of(item)
  end

  private

  def audio_binary
    Binary.create!(master_type: Binary::MasterType::ACCESS,
                   media_category: Binary::MediaCategory::AUDIO,
                   media_type: 'audio/wave',
                   object_key: 'audio',
                   byte_size: 0)
  end

  def document_binary
    Binary.create!(master_type: Binary::MasterType::ACCESS,
                   media_category: Binary::MediaCategory::DOCUMENT,
                   media_type: 'application/pdf',
                   object_key: 'document',
                   byte_size: 0)
  end

  def image_binary
    Binary.create!(master_type: Binary::MasterType::ACCESS,
                   media_category: Binary::MediaCategory::IMAGE,
                   media_type: 'image/jpeg',
                   object_key: 'image',
                   byte_size: 0)
  end

  def new_item
    Item.create!(collection_repository_id: collections(:sanborn).repository_id,
                 repository_id: SecureRandom.uuid)
  end

  def text_binary
    Binary.create!(master_type: Binary::MasterType::ACCESS,
                   media_category: Binary::MediaCategory::TEXT,
                   media_type: 'text/plain',
                   object_key: 'text',
                   byte_size: 0)
  end

  def three_d_binary
    Binary.create!(master_type: Binary::MasterType::ACCESS,
                   media_category: Binary::MediaCategory::THREE_D,
                   object_key: '3d',
                   byte_size: 0)
  end

  def video_binary
    Binary.create!(master_type: Binary::MasterType::ACCESS,
                   media_category: Binary::MediaCategory::VIDEO,
                   media_type: 'video/mpeg',
                   object_key: 'video',
                   byte_size: 0)
  end

end
