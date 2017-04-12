require 'test_helper'

class UpdateItemsFromTsvJobTest < ActiveSupport::TestCase

  # perform()

  ##
  # This is a minimal test that perform() returns. Testing of the actual TSV
  # updating happens in the test of ItemTsvUpdater.
  #
  test 'perform() should not crash' do
    file = Tempfile.new('test')
    begin
      file.close
      UpdateItemsFromTsvJob.perform_now(file.path, 'original.tsv')
      assert !File.exist?(file.path)
    ensure
      file.unlink
    end
  end

end
