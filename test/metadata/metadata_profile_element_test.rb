require 'test_helper'

class MetadataProfileElementTest < ActiveSupport::TestCase

  test 'controlled?() should work' do
    e = MetadataProfileElement.new(name: 'animal')
    assert !e.controlled?

    e.vocabularies << Vocabulary.uncontrolled
    assert !e.controlled?


    e.vocabularies.clear
    e.vocabularies << Vocabulary.create!(key: 'cats', name: 'Cats')
    assert e.controlled?
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

end
