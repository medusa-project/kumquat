require 'test_helper'

class IiifPdfGeneratorTest < ActiveSupport::TestCase

  setup do
    Item.reindex_all
    refresh_elasticsearch

    @instance = IiifPdfGenerator.new
  end

  # generate_pdf()

  test 'generate_pdf() returns nil when given a non-compound-object' do
    # File
    assert_nil @instance.generate_pdf(items(:free_form_dir1_dir1_file1))
    # Page
    assert_nil @instance.generate_pdf(items(:compound_object_1002_page1))
  end

  test 'generate_pdf() generates a PDF for compound objects' do
    begin
      item     = items(:compound_object_1002)
      pathname = @instance.generate_pdf(item)
      assert File.exists?(pathname)
      assert File.size(pathname) > 1000
    ensure
      File.delete(pathname) if pathname
    end
  end

end
