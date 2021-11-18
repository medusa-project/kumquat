require 'test_helper'

class BinaryTest < ActiveSupport::TestCase

  class MediaCategoryTest < ActiveSupport::TestCase

    test 'media_category_for_media_type() should return nil for a nil media type' do
      assert_nil Binary::MediaCategory::media_category_for_media_type(nil)
    end

    test 'media_category_for_media_type() should return nil for an unrecognized
    media type' do
      assert_nil Binary::MediaCategory::media_category_for_media_type('image/bogus')
    end

    test 'media_category_for_media_type() should work' do
      assert_equal Binary::MediaCategory::DOCUMENT,
                   Binary::MediaCategory::media_category_for_media_type('application/pdf')
      assert_equal Binary::MediaCategory::IMAGE,
                   Binary::MediaCategory::media_category_for_media_type('image/jpeg')
      assert_equal Binary::MediaCategory::TEXT,
                   Binary::MediaCategory::media_category_for_media_type('text/plain')
    end

  end

  setup do
    @instance = binaries(:free_form_dir1_dir1_file1)
  end

  # from_medusa_file()

  test 'from_medusa_file() returns an existing instance when one corresponding
  to the given file exists' do
    file   = Medusa::File.with_uuid('39582239-4307-1cc6-c9c6-074516fd7635')
    binary = Binary.from_medusa_file(file:        file,
                                     master_type: Binary::MasterType::PRESERVATION)
    assert !binary.new_record?
    assert_equal Binary::MasterType::ACCESS, binary.master_type
    assert_equal file.relative_key, binary.object_key
    assert_equal 6198, binary.byte_size
    assert_equal 'image/jpeg', binary.media_type
    assert_equal Binary::MediaCategory::IMAGE, binary.media_category
    assert_equal 128, binary.width
    assert_equal 112, binary.height
  end

  test 'from_medusa_file() returns a new instance when one corresponding to the
  given file does not already exist' do
    Binary.destroy_all
    file   = Medusa::File.with_uuid('084f6359-3213-35d7-a29b-bfee47b6dd9d')
    binary = Binary.from_medusa_file(file:        file,
                                     master_type: Binary::MasterType::PRESERVATION)
    assert binary.new_record?
    assert_equal Binary::MasterType::PRESERVATION, binary.master_type
    assert_equal file.relative_key, binary.object_key
    assert_equal 18836, binary.byte_size
    assert_equal 'image/jp2', binary.media_type
    assert_equal Binary::MediaCategory::IMAGE, binary.media_category
    assert_equal 128, binary.width
    assert_equal 112, binary.height
  end

  # data()

  test 'data() returns the data' do
    data = @instance.data
    #assert_kind_of IO, data # TODO: this is supposed to be an IO: https://docs.aws.amazon.com/sdk-for-ruby/v3/api/Aws/S3/Types/GetObjectOutput.html#body-instance_method
    assert_equal 11, data.length
  end

  # detect_text()

  test 'detect_text() raises an error if the instance is not an access master' do
    @instance.media_type = 'image/jpeg'
    @instance.master_type = Binary::MasterType::PRESERVATION
    assert_raises do
      @instance.detect_text
    end
  end

  test 'detect_text() raises an error if the instance is not an image or PDF' do
    @instance.media_type = 'application/zip'
    @instance.master_type = Binary::MasterType::ACCESS
    assert_raises do
      @instance.detect_text
    end
  end

  test 'detect_text() detects text' do
    # TODO: write this
  end

  # filename()

  test 'filename() should return the filename' do
    assert_equal('file1', @instance.filename)
  end

  # human_readable_media_category()

  test 'human_readable_media_category() should work properly' do
    assert_equal 'Audio',
                 Binary.new(media_category: Binary::MediaCategory::AUDIO).
                     human_readable_media_category
    assert_equal 'Binary',
                 Binary.new(media_category: Binary::MediaCategory::BINARY).
                     human_readable_media_category
    assert_equal 'Image',
                 Binary.new(media_category: Binary::MediaCategory::IMAGE).
                     human_readable_media_category
    assert_equal 'Document',
                 Binary.new(media_category: Binary::MediaCategory::DOCUMENT).
                     human_readable_media_category
    assert_equal 'Text',
                 Binary.new(media_category: Binary::MediaCategory::TEXT).
                     human_readable_media_category
    assert_equal '3D',
                 Binary.new(media_category: Binary::MediaCategory::THREE_D).
                     human_readable_media_category
    assert_equal 'Video',
                 Binary.new(media_category: Binary::MediaCategory::VIDEO).
                     human_readable_media_category
  end

  # human_readable_master_type()

  test 'human_readable_master_type should work properly' do
    assert_equal 'Access Master',
                 Binary.new(master_type: Binary::MasterType::ACCESS).human_readable_master_type
    assert_equal 'Preservation Master',
                 Binary.new(master_type: Binary::MasterType::PRESERVATION).human_readable_master_type
  end

  # human_readable_name()

  test 'human_readable_name() should work properly' do
    assert_equal 'JPEG', @instance.human_readable_name
  end

  # iiif_image_identifier()

  test 'iiif_image_identifier returns the correct identifier for images in Medusa' do
    assert_equal @instance.medusa_uuid, @instance.iiif_image_identifier
  end

  test 'iiif_image_identifier returns the correct identifier for images in MediaSpace' do
    @instance.media_type = 'video/cats'
    @instance.item.embed_tag = '<iframe id="kaltura_player" src="https://cdnapisec.kaltura.com/p/1329972/sp/132997200/embedIframeJs/uiconf_id/26883701/partner_id/1329972?iframeembed=true&playerId=kaltura_player&entry_id=1_l9epfpx1&flashvars[streamerType]=auto&flashvars[localizationCode]=en&flashvars[leadWithHTML5]=true&flashvars[sideBarContainer.plugin]=true&flashvars[sideBarContainer.position]=left&flashvars[sideBarContainer.clickToClose]=true&flashvars[chapters.plugin]=true&flashvars[chapters.layout]=vertical&flashvars[chapters.thumbnailRotator]=false&flashvars[streamSelector.plugin]=true&flashvars[EmbedPlayer.SpinnerTarget]=videoHolder&flashvars[dualScreen.plugin]=true&&wid=1_27eavjaq" width="640" height="480" allowfullscreen webkitallowfullscreen mozAllowFullScreen frameborder="0"></iframe>'
    assert_equal 'v/1329972/132997200/1_l9epfpx1',
                 @instance.iiif_image_identifier
  end

  # iiif_image_v2_url()

  test 'iiif_image_v2_url() returns correct URL' do
    assert_equal Configuration.instance.iiif_image_v2_url + '/' + @instance.medusa_uuid,
                 @instance.iiif_image_v2_url
  end

  # iiif_image_v3_url()

  test 'iiif_image_v3_url() returns correct URL' do
    assert_equal Configuration.instance.iiif_image_v3_url + '/' + @instance.medusa_uuid,
                 @instance.iiif_image_v3_url
  end

  # iiif_info_v2_url()

  test 'iiif_info_v2_url() returns a correct URL' do
    assert_equal Configuration.instance.iiif_image_v2_url + '/' + @instance.medusa_uuid + '/info.json',
                 @instance.iiif_info_v2_url
  end

  # iiif_info_v3_url()

  test 'iiif_info_v3_url() returns a correct URL' do
    assert_equal Configuration.instance.iiif_image_v3_url + '/' + @instance.medusa_uuid + '/info.json',
                 @instance.iiif_info_v3_url
  end

  # image_server_safe?()

  test 'image_server_safe?() returns false if the instance is not image
  server-compatible' do
    @instance.media_type = 'application/octet-stream'
    assert !@instance.image_server_safe?

    @instance.media_type = 'text/plain'
    assert !@instance.image_server_safe?
  end

  test 'image_server_safe?() returns false if a TIFF image is too big' do
    @instance.media_type = 'image/tiff'
    assert @instance.image_server_safe?
    @instance.byte_size = 30000001
    assert !@instance.image_server_safe?
  end

  test 'image_server_safe?() returns true in all other cases' do
    assert @instance.image_server_safe?
  end

  # infer_media_type()

  test 'infer_media_type() works' do
    @instance = binaries(:free_form_dir1_image1)
    @instance.media_type = nil
    @instance.infer_media_type
    assert_equal 'image/jpeg', @instance.media_type
  end

  # is_3d?()

  test 'is_3d?() works' do
    assert !@instance.is_3d?

    @instance.media_category = Binary::MediaCategory::THREE_D
    assert @instance.is_3d?
  end

  # is_audio?()

  test 'is_audio?() works' do
    assert !@instance.is_audio?

    @instance.media_type = 'audio/aiff'
    assert @instance.is_audio?
  end

  # is_document?()

  test 'is_document?() works' do
    assert !@instance.is_document?

    @instance.media_category = Binary::MediaCategory::DOCUMENT
    assert @instance.is_document?
  end

  # is_image?()

  test 'is_image?() works' do
    @instance.media_type = 'unknown/unknown'
    assert !@instance.is_image?

    @instance.media_type = 'image/jpeg'
    assert @instance.is_image?
  end

  # is_media_space_video?()

  test 'is_media_space_video?() works' do
    assert !@instance.is_media_space_video?

    @instance.media_type = 'video/mpeg'
    @instance.item.embed_tag = '<embed>kaltura</embed>'
    assert @instance.is_video?
  end

  # is_pdf?()

  test 'is_pdf?() works' do
    assert !@instance.is_pdf?

    @instance.media_type = 'application/pdf'
    assert @instance.is_pdf?
  end

  # is_pdf?()

  test 'is_raster?() works' do
    @instance.media_type = 'unknown/unknown'
    assert !@instance.is_raster?

    @instance.media_type = 'video/mpeg'
    assert @instance.is_raster?
    @instance.media_type = 'image/jpeg'
    assert @instance.is_raster?
  end

  # is_text?()

  test 'is_text?() works' do
    assert !@instance.is_text?

    @instance.media_type = 'text/plain'
    assert @instance.is_text?
  end

  # is_video?()

  test 'is_video?() returns false for non-videos' do
    assert !@instance.is_video?
  end

  test 'is_video?() returns true for videos' do
    @instance.media_type = 'video/mpeg'
    assert @instance.is_video?
  end

  # medusa_file()

  test 'medusa_file() returns an instance' do
    assert_not_nil @instance.medusa_file
  end

  # medusa_url()

  test 'medusa_url should return the Medusa URL' do
    assert_equal ::Configuration.instance.medusa_url + '/uuids/' + @instance.medusa_uuid,
                 @instance.medusa_url
  end

  test 'medusa_url should return nil if the Medusa file UUID is not set' do
    @instance.medusa_uuid = nil
    assert_nil @instance.medusa_url
  end

  # metadata()

  test 'metadata() returns metadata if metadata_json is set' do
    @instance = binaries(:free_form_dir1_image1)
    @instance.read_metadata
    assert @instance.metadata.length > 2
  end

  test 'metadata() returns an empty array if metadata_json is not set' do
    @instance = binaries(:free_form_dir1_image1)
    assert_kind_of Enumerable, @instance.metadata
  end

  # ocrable?()

  test 'ocrable() returns false if the instance is not an access master' do
    @instance.media_type  = 'image/jpeg'
    @instance.master_type = Binary::MasterType::PRESERVATION
    assert !@instance.ocrable?
  end

  test 'ocrable?() returns false if the instance is not an image or PDF' do
    @instance.media_type  = 'application/zip'
    @instance.master_type = Binary::MasterType::ACCESS
    assert !@instance.ocrable?
  end

  test 'ocrable?() returns true if the instance is an access master image' do
    @instance.media_type  = 'image/jpeg'
    @instance.master_type = Binary::MasterType::ACCESS
    assert @instance.ocrable?
  end

  test 'ocrable?() returns true if the instance is an access master PDF' do
    @instance.media_type  = 'application/pdf'
    @instance.master_type = Binary::MasterType::ACCESS
    assert @instance.ocrable?
  end

  # public?()

  test 'public?() returns false if neither the instance nor its collection are
  set public' do
    @instance.public = false
    @instance.item.collection.publicize_binaries = false
    assert !@instance.public?
  end

  test 'public?() returns false if the instance is set private but its collection is set public' do
    @instance.public = false
    @instance.item.collection.publicize_binaries = true
    assert !@instance.public?
  end

  test 'public?() returns false if the instance is set public but its collection is set private' do
    @instance.public = true
    @instance.item.collection.publicize_binaries = false
    assert !@instance.public?
  end

  test 'public?() returns true if the instance and its collection are set public' do
    @instance.public = true
    @instance.item.collection.publicize_binaries = true
    assert @instance.public?
  end

  # read_duration()

  test 'read_duration works with audio' do
    @instance = binaries(:free_form_dir1_audio)
    @instance.duration = nil
    @instance.read_duration
    assert_equal 0, @instance.duration
  end

  test 'read_duration works with video' do
    @instance          = binaries(:free_form_dir1_video)
    @instance.duration = nil
    @instance.read_duration
    assert_equal 2, @instance.duration
  end

  test 'read_duration raises an error with missing files' do
    @instance.media_type = 'audio/wav'
    @instance.object_key = 'bogus'
    assert_raises Aws::S3::Errors::NoSuchKey do
      @instance.read_duration
    end
  end

  # read_metadata()

  test 'read_metadata() works on images' do
    @instance = binaries(:free_form_dir1_image1)
    @instance.metadata_json = nil
    @instance.width         = nil
    @instance.height        = nil
    @instance.read_metadata

    assert_equal 128, @instance.width
    assert_equal 112, @instance.height
    assert_not_nil @instance.metadata_json
  end

  # uri()

  test 'uri returns the correct URI' do
    assert_equal "s3://#{MedusaS3Client::BUCKET}/#{@instance.object_key}",
                 @instance.uri
  end

  # word_coordinates()

  test 'word_coordinates() works with a word when using hOCR format' do
    binary      = binaries(:free_form_dir1_dir1_file1)
    binary.hocr = File.read(File.join(Rails.root, 'test', 'fixtures', 'ocr', 'tesseract.hocr'))
    result      = binary.word_coordinates('medicinal')
    assert_equal 14, result.length
    assert result[0][:x] > 0
    assert result[0][:y] > 0
    assert result[0][:width] > 0
    assert result[0][:height] > 0
  end

  test 'word_coordinates() works with a word when using Tesseract format' do
    binary                = binaries(:free_form_dir1_dir1_file1)
    binary.tesseract_json = File.read(File.join(Rails.root, 'test', 'fixtures', 'ocr', 'tesseract.json'))
    result                = binary.word_coordinates('century')
    assert_equal 4, result.length
    assert result[0][:x] > 0
    assert result[0][:y] > 0
    assert result[0][:width] > 0
    assert result[0][:height] > 0
  end

  test 'word_coordinates() works with a phrase when using hOCR format' do
    binary      = binaries(:free_form_dir1_dir1_file1)
    binary.hocr = File.read(File.join(Rails.root, 'test', 'fixtures', 'ocr', 'tesseract.hocr'))
    result      = binary.word_coordinates('salvia officinalis.')
    assert_equal 3, result.length
  end

  test 'word_coordinates() works with a phrase when using Tesseract format' do
    binary                = binaries(:free_form_dir1_dir1_file1)
    binary.tesseract_json = File.read(File.join(Rails.root, 'test', 'fixtures', 'ocr', 'tesseract.json'))
    result                = binary.word_coordinates('duced to britain')
    assert_equal 3, result.length
  end

end
