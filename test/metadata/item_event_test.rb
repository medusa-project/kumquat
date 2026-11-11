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

  test 'search lets users filter events log based on query' do 
    first = { 'value' => 'First', 'uri' => '', 'vocabulary_id' => 1 }
    second = { 'value' => 'Second', 'uri' => '', 'vocabulary_id' => 1 }
    event1 = ItemEvent.create!(event_type: 'metadata_updated', changeset: {
      'description' => { 'before' => [], 'after' => [first] }
    })
    event2 = ItemEvent.create!(event_type: 'metadata_updated', changeset: {
      'description' => { 'before' => [], 'after' => [second] }
    })

    results = ItemEvent.joins(:item).where(
      "item_events.changeset::text ILIKE :query OR " \
      "items.repository_id ILIKE :query OR " \
      "EXISTS (SELECT 1 FROM entity_elements " \
      "WHERE entity_elements.item_id = items.id " \
      "AND entity_elements.name = 'title' " \
      "AND entity_elements.value ILIKE :query)",
      query: "%First%"
    )

    assert_includes results, event1
    assert_not_includes results, event2
  end
end
