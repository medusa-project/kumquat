require "test_helper"

class ItemEventTest < ActiveSupport::TestCase
  
  test 'change_summary identifies reversed entries within a vocabulary group' do
    first = { 'value' => 'First', 'uri' => '', 'vocabulary_id' => 1 }
    second = { 'value' => 'Second', 'uri' => '', 'vocabulary_id' => 1 }
    other = { 'value' => 'Other', 'uri' => '', 'vocabulary_id' => 2 }
    event = ItemEvent.new(event_type: 'metadata_updated', changeset: {
      'description' => {
        'before' => [first, second, other],
        'after' => [second, first, other]
      }
    })

    assert_equal 'Values reversed', event.change_summary
  end

  test 'change_summary distinguishes additions removals edits and reordering' do
    first = { 'value' => 'First', 'uri' => '', 'vocabulary_id' => 1 }
    second = { 'value' => 'Second', 'uri' => '', 'vocabulary_id' => 1 }
    third = { 'value' => 'Third', 'uri' => '', 'vocabulary_id' => 1 }
    cases = [
      [[], [first], 'Values added'],
      [[first], [], 'Values removed'],
      [[first], [second], 'Values edited'],
      [[first], [first, first], 'Values added'],
      [[first, second, third], [second, first, third], 'Values reordered'],
      [[first], [first.merge('uri' => 'https://example.org/first')], 'Values edited']
    ]

    cases.each do |before_entries, after_entries, expected|
      event = ItemEvent.new(event_type: 'metadata_updated', changeset: {
        'description' => { 'before' => before_entries, 'after' => after_entries }
      })
      assert_equal expected, event.change_summary
    end
  end

  test 'change_summary combines actions from multiple changed fields' do
    first = { 'value' => 'First', 'uri' => '', 'vocabulary_id' => 1 }
    second = { 'value' => 'Second', 'uri' => '', 'vocabulary_id' => 1 }
    event = ItemEvent.new(event_type: 'metadata_updated', changeset: {
      'description' => { 'before' => [first, second], 'after' => [second, first] },
      'title' => { 'before' => [first], 'after' => [second] }
    })

    assert_equal 'Values reversed; Values edited', event.change_summary
  end
end
