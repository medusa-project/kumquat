require 'test_helper'

class SpaceUtilTest < ActiveSupport::TestCase

  test 'string_coordinates_to_coordinates() with an unrecognizable argument
  should return nil' do
    assert_nil SpaceUtil.string_coordinates_to_coordinates('cats')
  end

  test 'string_coordinates_to_coordinates should work with various formats' do
    # DD⁰MM'SS"N/DD⁰MM'SS"E
    assert_equal({ latitude: 45.7625, longitude: 61.016666666666666 },
                 SpaceUtil.string_coordinates_to_coordinates('45⁰45\'45"N/60⁰60\'60"E'))

    # DD⁰MM'SS"S / DD⁰MM'SS"W
    assert_equal({ latitude: -45.7625, longitude: -61.016666666666666 },
                 SpaceUtil.string_coordinates_to_coordinates('45⁰45\'45" S / 60⁰60\'60"W'))

    # DD⁰MM'SS"E/DD⁰MM'SS"N
    assert_equal({ latitude: 45.7625, longitude: 61.016666666666666 },
                 SpaceUtil.string_coordinates_to_coordinates('60⁰60\'60"E/45⁰45\'45"N'))

    # DD MM SS E/DD MM SS N
    assert_equal({ latitude: 45.7625, longitude: 61.016666666666666 },
                 SpaceUtil.string_coordinates_to_coordinates('60 60 60 E/45 45 45 N'))
  end

end
