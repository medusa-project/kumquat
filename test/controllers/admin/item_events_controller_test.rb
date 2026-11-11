require 'test_helper'

module Admin

  class ItemEventsControllerTest < ActionDispatch::IntegrationTest

    setup do 
      @item = items(:compound_object_1001)
      @user = users(:medusa_admin)
      sign_out
    end

  test 'search lets users filter events log based on query' do 

    first = { 'value' => 'First', 'uri' => '', 'vocabulary_id' => 1 }
    second = { 'value' => 'Second', 'uri' => '', 'vocabulary_id' => 1 }

    sign_in_as(@user)
    
    ItemEvent.create!(item: @item, user: @user, event_type: 'metadata_updated', changeset: {
      'description' => { 'before' => [], 'after' => [first] }
    })
    ItemEvent.create!(item: @item, user: @user, event_type: 'metadata_updated', changeset: {
      'subject' => { 'before' => [], 'after' => [second] }
    })
    
    get admin_item_events_path, params: { q: 'First' }

    assert_response :success
    assert_includes response.body, 'description'
    assert_not_includes response.body, 'subject'
  end
end