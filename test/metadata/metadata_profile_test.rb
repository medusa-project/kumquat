require 'test_helper'

class MetadataProfileTest < ActiveSupport::TestCase

  test 'default_element_defs should work' do
    assert MetadataProfile.default_element_defs.length > 20
  end

end
