require 'test_helper'

class IiifPdfGeneratorTest < ActiveSupport::TestCase

  setup do
    Item.reindex_all
    setup_elasticsearch

    @instance = IiifPdfGenerator.new
  end

  # generate_pdf()

  test 'generate_pdf() returns nil when given a non-compound-object' do
    # File
    assert_nil @instance.generate_pdf(item: items(:free_form_dir1_dir1_file1))
    # Page
    assert_nil @instance.generate_pdf(item: items(:compound_object_1002_page1))
  end

  test 'generate_pdf() generates a PDF for compound objects' do
    begin
      item     = items(:compound_object_1002)
      pathname = @instance.generate_pdf(item: item)
      assert File.exists?(pathname)
      assert File.size(pathname) > 1000
    ensure
      File.delete(pathname) if pathname
    end
  end

  test 'generate_pdf() omits private binaries' do
    item = items(:compound_object_1002)
    # generate an ordinary PDF with no private binaries and capture its size
    # (ideally we would capture the page count but Prawn can only generate
    # documents, not read existing ones)
    begin
      pathname = @instance.generate_pdf(item: item)
      size = File.size(pathname)
    ensure
      File.delete(pathname) if pathname
    end

    # mark the first binary of the first child private and generate another PDF
    Binary.find_by_medusa_uuid('a9bdc6af-fecb-6ed9-2ca9-e577fd1455ed').update!(public: false)
    begin
      pathname = @instance.generate_pdf(item: item)
      assert size - File.size(pathname) > 100
    ensure
      File.delete(pathname) if pathname
    end
  end

end
