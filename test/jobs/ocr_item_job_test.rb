require 'test_helper'

class OcrItemJobTest < ActiveSupport::TestCase

  # perform()

  test 'perform()' do
    item = items(:compound_object_1001)
    Binary.create!(item: item, master_type: Binary::MasterType::ACCESS,
                            media_type: 'image/png')

    Binary.any_instance.stubs(:detect_text).returns(true)
    OcrItemJob.perform_now(item: item, language_code: 'eng', include_already_ocred: true)

    item.reload 
    assert_equal true, item.ocred?
  end

end
