require 'test_helper'

class ItemsHelperTest < ActionView::TestCase

  # viewer_for_binary()

  test 'viewer_for_binary() should work with PDFs' do
    binary = binaries(:iptc)
    binary.media_type = 'application/pdf'
    assert viewer_for_binary(binary).include?('id="pt-pdf-viewer"')
  end

  test 'viewer_for_binary() should work with audio' do
    binary = binaries(:iptc)
    binary.media_type = 'audio/wav'
    assert viewer_for_binary(binary).include?('id="pt-audio-player"')
  end

  test 'viewer_for_binary() should work with video' do
    binary = binaries(:iptc)
    binary.media_type = 'video/mpeg'
    assert viewer_for_binary(binary).include?('id="pt-video-player"')
  end

  test 'viewer_for_binary() should work with text' do
    # TODO: find a text binary and then write this
  end

  # viewer_for_item()

  test 'viewer_for_item() should work for items with an embed tag' do
    item = items(:iptc_item)
    item.embed_tag = '<embed></embed>'
    assert viewer_for_item(item).include?('<embed width="100%" height="600"')
  end

  test 'viewer_for_item() should work for non-PDF file items' do
    item = items(:free_form_dir1_file1)
    assert viewer_for_item(item).include?('id="pt-compound-viewer"')
  end

  test 'viewer_for_item() should work for compound items' do
    item = items(:map_obj1)
    assert viewer_for_item(item).include?('id="pt-compound-viewer"')
  end

  test 'viewer_for_item() should work for image items' do
    item = items(:map_obj1_page1)
    assert viewer_for_item(item).include?('id="pt-image-viewer"')
  end

  test 'viewer_for_item() should work for PDF items' do
    item = items(:map_obj1_page1)
    item.access_master_binary.media_type = 'application/pdf'
    assert viewer_for_item(item).include?('id="pt-pdf-viewer"')
  end

  test 'viewer_for_item() should work for audio items' do
    item = items(:map_obj1_page1)
    item.access_master_binary.media_type = 'audio/mp3'
    assert viewer_for_item(item).include?('id="pt-audio-player"')
  end

  test 'viewer_for_item() should work for video items' do
    item = items(:map_obj1_page1)
    item.access_master_binary.media_type = 'video/mpeg'
    assert viewer_for_item(item).include?('id="pt-video-player"')
  end

  test 'viewer_for_item() should work for text items' do
    # TODO: find a text item and then write this
  end

end
