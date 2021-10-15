require 'test_helper'

class MetadataProfileElementTest < ActiveSupport::TestCase

  setup do
    @element = metadata_profile_elements(:default_profile_title)
    assert @element.validate
  end

  # controlled?()

  test 'controlled?() works' do
    e = MetadataProfileElement.new(name: 'animal')
    assert !e.controlled?

    e.vocabularies << Vocabulary.uncontrolled
    assert !e.controlled?

    e.vocabularies.clear
    e.vocabularies << Vocabulary.create!(key: 'cats', name: 'Cats')
    assert e.controlled?
  end

  # create()

  test 'create() updates indexes in the owning profile' do
    profile = metadata_profiles(:default)
    MetadataProfileElement.create!(name:             'rights',
                                   index:            1,
                                   metadata_profile: profile,
                                   vocabularies:     [vocabularies(:uncontrolled)])
    # Assert that the indexes are sequential and zero-based.
    profile.elements.order(:index).each_with_index do |e, i|
      assert_equal i, e.index
    end
  end

  # data_type

  test 'data_type must be in the range of DataType constants' do
    assert @element.valid?

    @element.data_type = nil
    assert !@element.valid?

    @element.data_type = -1
    assert !@element.valid?

    @element.data_type = 25
    assert !@element.valid?
  end

  # destroy()

  test 'destroy() updates indexes in the owning profile' do
    profile = @element.metadata_profile
    @element.destroy!
    # Assert that the indexes are sequential and zero-based.
    profile.elements.order(:index).each_with_index do |e, i|
      assert_equal i, e.index
    end
  end

  # human_readable_data_type()

  test 'human_readable_data_type() returns the correct string' do
    @element.data_type = MetadataProfileElement::DataType::SINGLE_LINE_STRING
    assert_equal 'Single-Line String', @element.human_readable_data_type

    @element.data_type = MetadataProfileElement::DataType::MULTI_LINE_STRING
    assert_equal 'Multi-Line String', @element.human_readable_data_type
  end

  # update()

  test 'update() updates indexes in the owning profile when increasing an
  element index' do
    assert_equal 0, @element.index
    @element.update!(index: 3)
    # Assert that the indexes are sequential and zero-based.
    @element.metadata_profile.elements.order(:index).each_with_index do |e, i|
      assert_equal i, e.index
    end
  end

  test 'update() updates indexes in the owning profile when decreasing an
  element index' do
    @element = @element.metadata_profile.elements.where(index: 3).first
    @element.update!(index: 0)
    # Assert that the indexes are sequential and zero-based.
    @element.metadata_profile.elements.order(:index).each_with_index do |e, i|
      assert_equal i, e.index
    end
  end

  # validate()

  test 'validate() requires unique names' do
    @element.metadata_profile.elements.each_with_index do |e, i|
      e.name = 'title'
      if i == 0
        e.save!
      else
        assert_raises ActiveRecord::RecordInvalid do
          e.save!
        end
      end
    end
  end

  test 'validate() disallows negative indexes' do
    @element.index = -1
    assert !@element.validate
  end

  test 'validate() requires at least one associated vocabulary' do
    @element.vocabularies.clear
    assert !@element.validate

    @element.vocabularies << vocabularies(:uncontrolled)
    assert @element.validate
  end

end
