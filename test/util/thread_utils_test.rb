require 'test_helper'

class ThreadUtilsTest < ActiveSupport::TestCase

  # process_in_parallel()

  test 'process_in_parallel() works with a thread count of 1' do
    test_with_thread_count(1)
  end

  test 'process_in_parallel() works with a thread count of 2' do
    test_with_thread_count(2)
  end

  test 'process_in_parallel() works with a thread count of 3' do
    test_with_thread_count(3)
  end

  test 'process_in_parallel() works with a larger thread count than item length' do
    test_with_thread_count(150)
  end


  private

  def test_with_thread_count(thread_count)
    items = ['a'] * 100
    ThreadUtils.process_in_parallel(items, num_threads: thread_count) do |item|
      item.upcase!
    end
    expected_items = ['A'] * 100
    assert_equal expected_items, items
  end

end
