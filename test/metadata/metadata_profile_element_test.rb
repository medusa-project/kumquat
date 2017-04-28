require 'test_helper'

class MetadataProfileElementTest < ActiveSupport::TestCase

  setup do
    @element = metadata_profile_elements(:default_profile_title)
    assert @element.validate
  end

  # controlled?()

  test 'controlled?() should work' do
    e = MetadataProfileElement.new(name: 'animal')
    assert !e.controlled?

    e.vocabularies << Vocabulary.uncontrolled
    assert !e.controlled?

    e.vocabularies.clear
    e.vocabularies << Vocabulary.create!(key: 'cats', name: 'Cats')
    assert e.controlled?
  end

  # create()

  test 'create() should update indexes in the owning profile' do
    profile = metadata_profiles(:default_metadata_profile)
    MetadataProfileElement.create!(name: 'rights',
                                   index: 1,
                                   metadata_profile: profile)
    # Assert that the indexes are sequential and zero-based.
    profile.elements.order(:index).each_with_index do |e, i|
      assert_equal i, e.index
    end
  end

  # destroy()

  test 'destroy() should update indexes in the owning profile' do
    profile = @element.metadata_profile
    @element.destroy!
    # Assert that the indexes are sequential and zero-based.
    profile.elements.order(:index).each_with_index do |e, i|
      assert_equal i, e.index
    end
  end

  # update()

  test 'update() should update indexes in the owning profile when increasing an
  element index' do
    assert_equal 0, @element.index
    @element.update!(index: 3)
    # Assert that the indexes are sequential and zero-based.
    @element.metadata_profile.elements.order(:index).each_with_index do |e, i|
      assert_equal i, e.index
    end
  end

  test 'update() should update indexes in the owning profile when decreasing an
  element index' do
    @element = @element.metadata_profile.elements.where(index: 3).first
    @element.update!(index: 0)
    # Assert that the indexes are sequential and zero-based.
    @element.metadata_profile.elements.order(:index).each_with_index do |e, i|
      assert_equal i, e.index
    end
  end

  # validate()

  test 'validate() should require unique names' do
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

  test 'validate() should disallow negative indexes' do
    @element.index = -1
    assert !@element.validate
  end

end
