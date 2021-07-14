require 'test_helper'

class TaskTest < ActiveSupport::TestCase

  test 'estimated_completion() returns nil for a waiting task' do
    task = tasks(:waiting)
    assert_nil task.estimated_completion
  end

  test 'estimated_completion() returns an accurate figure for a running task' do
    task = tasks(:running)
    assert task.estimated_completion > Time.now
    assert task.estimated_completion < Time.now + 2.hours
  end

  test 'estimated_completion() returns an accurate figure for a paused task' do
    task = tasks(:paused)
    assert task.estimated_completion > Time.now
    assert task.estimated_completion < Time.now + 2.hours
  end

  test 'estimated_completion() returns nil for a succeeded task' do
    task = tasks(:succeeded)
    assert_nil task.estimated_completion
  end

  test 'estimated_completion() returns nil for a failed task' do
    task = tasks(:failed)
    assert_nil task.estimated_completion
  end

end
