require 'test_helper'

class UpdateItemsFromTsvJobTest < ActiveSupport::TestCase

  # perform()

  ##
  # This is a minimal test that perform() returns. Testing of the actual TSV
  # updating happens in the test of ItemUpdater.
  #
  test 'perform() should not crash' do
    file = Tempfile.new('test')
    begin
      file.close
      UpdateItemsFromTsvJob.perform_now(tsv_pathname:          file.path,
                                        tsv_original_filename: 'original.tsv')
      assert !File.exist?(file.path)
    ensure
      file.close
      file.unlink
    end
  end

end
