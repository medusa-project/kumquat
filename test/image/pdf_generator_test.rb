require 'test_helper'

class PdfGeneratorTest < ActiveSupport::TestCase

  setup do
    setup_opensearch
    Item.reindex_all
    refresh_opensearch
    @instance = PdfGenerator.new
  end

  # generate_pdf()

  test 'generate_pdf() generates a PDF for compound objects' do
    item     = items(:compound_object_1002)
    pathname = @instance.generate_pdf(item: item)
    assert File.exist?(pathname)
    assert File.size(pathname) > 1000
  ensure
    FileUtils.rm_f(pathname) if pathname
  end

  test 'generate_pdf() generates a PDF for compound object pages' do
    item     = items(:compound_object_1002_page1)
    pathname = @instance.generate_pdf(item: item)
    assert File.exist?(pathname)
    assert File.size(pathname) > 1000
  ensure
    FileUtils.rm_f(pathname) if pathname
  end

  test 'generate_pdf() generates a PDF for single-item objects' do
    item     = items(:compound_object_1001)
    pathname = @instance.generate_pdf(item: item)
    assert File.exist?(pathname)
    assert File.size(pathname) > 1000
  ensure
    FileUtils.rm_f(pathname) if pathname
  end

  test 'generate_pdf() generates a PDF for free-form file items' do
    item     = items(:free_form_dir1_image)
    pathname = @instance.generate_pdf(item: item)
    assert File.exist?(pathname)
    assert File.size(pathname) > 1000
  ensure
    FileUtils.rm_f(pathname) if pathname
  end

  test 'generate_pdf() omits private binaries' do
    item = items(:compound_object_1002)
    # generate an ordinary PDF with no private binaries and capture its size
    # (ideally we would capture the page count but Prawn can only generate
    # documents, not read existing ones)
    begin
      pathname = @instance.generate_pdf(item: item)
      initial_size = File.size(pathname)
    ensure
      FileUtils.rm_f(pathname) if pathname
    end

    # mark the first binary of the first child private and generate another PDF
    Binary.find_by_medusa_uuid('a9bdc6af-fecb-6ed9-2ca9-e577fd1455ed').update!(public: false)
    begin
      pathname = @instance.generate_pdf(item: item)
      assert initial_size > File.size(pathname)
    ensure
      FileUtils.rm_f(pathname) if pathname
    end
  end

end
