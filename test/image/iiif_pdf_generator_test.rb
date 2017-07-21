require 'test_helper'

class IiifPdfGeneratorTest < ActiveSupport::TestCase

  setup do
    @instance = IiifPdfGenerator.new
  end

  # generate_pdf()

  test 'generate_pdf() should return nil when given a non-compound-object' do
    # File
    assert_nil @instance.generate_pdf(items(:illini_union_dir1_file1))
    # Page
    assert_nil @instance.generate_pdf(items(:sanborn_obj1_page1))
  end

  test 'generate_pdf() should generate a PDF for compound objects' do
    begin
      item = items(:sanborn_obj1)
      pathname = @instance.generate_pdf(item)
      assert File.exists?(pathname)
      assert File.size(pathname) > 10000
    ensure
      FileUtils.rm(pathname) if pathname
    end
  end

end
