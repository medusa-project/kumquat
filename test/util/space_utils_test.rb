require 'test_helper'

class SpaceUtilsTest < ActiveSupport::TestCase

  test 'string_coordinates_to_coordinates() with a nil argument should return
  nil' do
    assert_nil SpaceUtils.string_coordinates_to_coordinates(nil)
  end

  test 'string_coordinates_to_coordinates() with an unrecognizable argument
  should return nil' do
    assert_nil SpaceUtils.string_coordinates_to_coordinates('cats')
  end

  test 'string_coordinates_to_coordinates() should work with DD⁰MM\'SS"N/DD⁰MM\'SS"E' do
    assert_equal({ latitude: 45.7625, longitude: 61.016666666666666 },
                 SpaceUtils.string_coordinates_to_coordinates('45⁰45\'45"N/60⁰60\'60"E'))
  end

  test 'string_coordinates_to_coordinates() should work with DD⁰MM\'SS"S / DD⁰MM\'SS"W' do
    assert_equal({ latitude: -45.7625, longitude: -61.016666666666666 },
                 SpaceUtils.string_coordinates_to_coordinates('45⁰45\'45" S / 60⁰60\'60"W'))
  end

  test 'string_coordinates_to_coordinates() should work with DD⁰MM\'SS"E/DD⁰MM\'SS"N' do
    assert_equal({ latitude: 45.7625, longitude: 61.016666666666666 },
                 SpaceUtils.string_coordinates_to_coordinates('60⁰60\'60"E/45⁰45\'45"N'))
  end

  test 'string_coordinates_to_coordinates() should work with DD MM SS E/DD MM SS N' do
    assert_equal({ latitude: 45.7625, longitude: 61.016666666666666 },
                 SpaceUtils.string_coordinates_to_coordinates('60 60 60 E/45 45 45 N'))
  end

end
