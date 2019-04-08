require 'test_helper'

class ItemsHelperTest < ActionView::TestCase

  # viewer_for_binary()

  test 'viewer_for_binary() should work with PDFs' do
    binary = binaries(:illini_union_dir1_dir1_file1)
    binary.media_type = 'application/pdf'
    assert viewer_for_binary(binary).include?('id="dl-pdf-viewer"')
  end

  test 'viewer_for_binary() should work with audio' do
    binary = binaries(:illini_union_dir1_dir1_file1)
    binary.media_type = 'audio/wav'
    assert viewer_for_binary(binary).include?('id="dl-audio-player"')
  end

  test 'viewer_for_binary() should work with video' do
    binary = binaries(:illini_union_dir1_dir1_file1)
    binary.media_type = 'video/mpeg'
    assert viewer_for_binary(binary).include?('id="dl-video-player"')
  end

  test 'viewer_for_binary() should work with text' do
    # TODO: find a text binary and then write this
  end

  # viewer_for_item()

  test 'viewer_for_item() should work for items with an embed tag' do
    item = items(:illini_union_dir1_dir1_file1)
    item.embed_tag = '<embed></embed>'
    assert viewer_for_item(item).include?('<embed width="100%" height="600"')
  end

  test 'viewer_for_item() should work for non-PDF file items' do
    item = items(:illini_union_dir1_dir1_file1)
    item.binaries.build(media_category: Binary::MediaCategory::IMAGE)
    assert viewer_for_item(item).include?('id="dl-image-viewer"')
  end

  test 'viewer_for_item() should work for compound items' do
    item = items(:sanborn_obj1)
    assert viewer_for_item(item).include?('id="dl-compound-viewer"')
  end

  test 'viewer_for_item() should work for image items' do
    item = items(:sanborn_obj1_page1)
    assert viewer_for_item(item).include?('id="dl-image-viewer"')
  end

  test 'viewer_for_item() should work for PDF items' do
    item = items(:sanborn_obj1_page1)
    item.binaries.select{ |b| b.master_type == Binary::MasterType::ACCESS }.
        first.media_category = Binary::MediaCategory::DOCUMENT
    assert viewer_for_item(item).include?('id="dl-pdf-viewer"')
  end

  test 'viewer_for_item() should work for audio items' do
    item = items(:sanborn_obj1_page1)
    item.binaries.select{ |b| b.master_type == Binary::MasterType::ACCESS }.
        first.media_category = Binary::MediaCategory::AUDIO
    assert viewer_for_item(item).include?('id="dl-audio-player"')
  end

  test 'viewer_for_item() should work for video items' do
    item = items(:sanborn_obj1_page1)
    am = item.binaries.select{ |b| b.master_type == Binary::MasterType::ACCESS }.first
    am.media_type = 'video/mpeg'
    am.media_category = Binary::MediaCategory::media_category_for_media_type(am.media_type)
    assert viewer_for_item(item).include?('id="dl-video-player"')
  end

  test 'viewer_for_item() should work for text items' do
    # TODO: find a text item and then write this
  end

end
