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

  test 'validate() should disallow negative indexes' do
    @element.index = -1
    assert !@element.validate
  end

end
