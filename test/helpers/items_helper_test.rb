require 'test_helper'

class ItemsHelperTest < ActionView::TestCase

  include SessionsHelper
  include ERB::Util

  # viewer_for_binary()

  test 'viewer_for_binary() should work with PDFs' do
    binary = binaries(:free_form_dir1_dir1_file1)
    binary.media_type = 'application/pdf'
    assert viewer_for_binary(binary).include?('id="dl-pdf-viewer"')
  end

  test 'viewer_for_binary() should work with audio' do
    binary = binaries(:free_form_dir1_dir1_file1)
    binary.media_type = 'audio/wav'
    assert viewer_for_binary(binary).include?('id="dl-audio-player"')
  end

  test 'viewer_for_binary() should work with video' do
    binary = binaries(:free_form_dir1_dir1_file1)
    binary.media_type = 'video/mpeg'
    assert viewer_for_binary(binary).include?('id="dl-video-player"')
  end

  test 'viewer_for_binary() should work with text' do
    # TODO: find a text binary and then write this
  end

  # viewer_for_item()

  test 'viewer_for_item() should work for items with an embed tag' do
    item = items(:free_form_dir1_dir1_file1)
    item.embed_tag = '<embed></embed>'
    assert viewer_for_item(item).include?('<embed ')
  end

  test 'viewer_for_item() should work for non-PDF file items' do
    item = items(:free_form_dir1_dir1_file1)
    item.binaries.build(media_category: Binary::MediaCategory::IMAGE)
    assert viewer_for_item(item).include?('id="dl-image-viewer"')
  end

  test 'viewer_for_item() should work for compound items' do
    item = items(:compound_object_1002)
    assert viewer_for_item(item).include?('id="dl-compound-viewer"')
  end

  test 'viewer_for_item() should work for image items' do
    item = items(:compound_object_1002_page1)
    assert viewer_for_item(item).include?('id="dl-image-viewer"')
  end

  test 'viewer_for_item() should work for PDF items' do
    item = items(:compound_object_1002_page1)
    item.binaries.find{ |b| b.master_type == Binary::MasterType::ACCESS }.
        media_category = Binary::MediaCategory::DOCUMENT
    assert viewer_for_item(item).include?('id="dl-pdf-viewer"')
  end

  test 'viewer_for_item() should work for audio items' do
    item = items(:free_form_dir1_audio)
    item.binaries.find{ |b| b.master_type == Binary::MasterType::ACCESS }.
        media_category = Binary::MediaCategory::AUDIO
    assert viewer_for_item(item).include?('id="dl-audio-player"')
  end

  test 'viewer_for_item() should work for video items' do
    item = items(:compound_object_1002_page1)
    am = item.binaries.find{ |b| b.master_type == Binary::MasterType::ACCESS }
    am.media_type     = 'video/mpeg'
    am.media_category = Binary::MediaCategory::media_category_for_media_type(am.media_type)
    assert viewer_for_item(item).include?('id="dl-video-player"')
  end

  test 'viewer_for_item() should work for text items' do
    # TODO: find a text item and then write this
  end

  test 'viewer_for_item() should render the 3D viewer for THREE_D_MODEL variant items' do
    item = items(:compound_object_1002_page1)
    item.variant = Item::Variants::THREE_D_MODEL

    # Simulate the real-world case: OBJ and MTL binaries with nil master_type,
    # which causes effective_viewer_binary to return nil and previously produced
    # a blank panel. The filename is derived from object_key.
    item.binaries.build(
      object_key:     'models/model.obj',
      medusa_uuid:    SecureRandom.uuid,
      media_category: Binary::MediaCategory::THREE_D,
      media_type:     'text/plain',
      master_type:    nil,
      public:         true
    )
    item.binaries.build(
      object_key:     'models/model.mtl',
      medusa_uuid:    SecureRandom.uuid,
      media_category: Binary::MediaCategory::THREE_D,
      media_type:     'text/plain',
      master_type:    nil,
      public:         true
    )

    result = viewer_for_item(item)
    assert result.include?('ThreeJSViewer'), 'Expected 3D viewer script but got blank/nil'
    assert result.include?('dl-3d-viewer'),  'Expected 3D viewer container div'
  end

  test 'viewer_for_item() should render the 3D viewer, not the image viewer, when a THREE_D_MODEL item also has an image binary' do
    item = items(:compound_object_1002_page1)
    item.variant = Item::Variants::THREE_D_MODEL

    # An image binary with ACCESS master_type — effective_viewer_binary would
    # have previously picked this up and rendered the image viewer instead.
    item.binaries.build(
      object_key:     'thumbnails/thumbnail.jpg',
      medusa_uuid:    SecureRandom.uuid,
      media_category: Binary::MediaCategory::IMAGE,
      media_type:     'image/jpeg',
      master_type:    Binary::MasterType::ACCESS,
      public:         true
    )
    item.binaries.build(
      object_key:     'models/model.obj',
      medusa_uuid:    SecureRandom.uuid,
      media_category: Binary::MediaCategory::THREE_D,
      media_type:     'text/plain',
      master_type:    nil,
      public:         true
    )
    item.binaries.build(
      object_key:     'models/model.mtl',
      medusa_uuid:    SecureRandom.uuid,
      media_category: Binary::MediaCategory::THREE_D,
      media_type:     'text/plain',
      master_type:    nil,
      public:         true
    )

    result = viewer_for_item(item)
    assert result.include?('ThreeJSViewer'),     'Expected 3D viewer, not image viewer'
    assert result.include?('dl-3d-viewer'),      'Expected 3D viewer container div'
    assert_not result.include?('dl-image-viewer'), 'Image viewer should not render for 3D model items'
  end

end
