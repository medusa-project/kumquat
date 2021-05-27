##
# Assembles PDFs for single items and compound objects.
#
# @see http://prawnpdf.org/manual.pdf
#
class PdfGenerator

  LOGGER = CustomLogger.new(PdfGenerator)

  # N.B.: document coordinates are expressed in points (1/72 inch).
  DOCUMENT_PPI       = 72   # points/inch
  IMAGE_DPI          = 200  # pixels/inch; tradeoff between quality and size
  MARGIN_INCHES      = 0.25
  PAGE_WIDTH_INCHES  = 8.5
  PAGE_HEIGHT_INCHES = 11

  def initialize
    Prawn::Fonts::AFM.hide_m17n_warning = true
  end

  ##
  # Assembles the {Binary#public public} access master image binaries of all of
  # a compound object's child items into a PDF. If the instance has no child
  # items, the item itself is compiled into a one-page PDF. If word coordinates
  # are available, word boxes are drawn underneath the image(s) to facilitate
  # copying and searching.
  #
  # @param item [Item]
  # @param include_private_binaries [Boolean]
  # @param task [Task] Optional; supply to receive progress updates.
  # @return [String, nil] Pathname of the generated PDF, or nil if there are no
  #                       images to add to the PDF.
  #
  def generate_pdf(item:, include_private_binaries: false, task: nil)
    reset
    doc = new_pdf_document(item)
    draw_title_page(item, doc)
    items = item.search_children.to_a
    items = [item] if items.empty?
    count = items.count
    items.each_with_index do |item_, index|
      binaries = item_.binaries.where(
          master_type:    Binary::MasterType::ACCESS,
          media_category: Binary::MediaCategory::IMAGE)
      binaries = binaries.where(public: true) unless include_private_binaries
      binaries.each do |binary|
        doc.start_new_page(layout: ((binary.width || 0) > (binary.height || 0)) ?
                                     :landscape : :portrait)
        draw_item_page(binary, doc)
      end
      task&.progress = index / count.to_f
    end
    create_outline(item, items, doc)
    tempfile = pdf_temp_file
    doc.render_file(tempfile.path)
    tempfile.path
  ensure
    FileUtils.rm_rf(image_temp_dir)
  end


  private

  include Rails.application.routes.url_helpers

  def draw_title_page(item, doc)
    doc.stroke_bounds
    doc.move_down doc.bounds.height / 5.0

    box_margin = 20

    # Title
    doc.bounding_box([box_margin, doc.bounds.height * 0.85],
                     width: doc.bounds.width - box_margin * 2,
                     height: doc.bounds.height * 0.4) do
      #doc.transparent(0.5) { doc.stroke_bounds }
      doc.text(item.title,
               align: :center,
               overflow: :shrink_to_fit,
               size: 32)
    end

    # Collection
    doc.bounding_box([box_margin, doc.bounds.height * 0.4 + box_margin],
                     width: doc.bounds.width - box_margin * 2,
                     height: 48) do
      #doc.transparent(0.5) { doc.stroke_bounds }
      doc.text(item.collection.title,
               align: :center,
               overflow: :shrink_to_fit,
               size: 18)
    end

    # Source
    doc.bounding_box([box_margin, doc.bounds.height * 0.3 + box_margin],
                     width: doc.bounds.width - box_margin * 2,
                     height: 48) do
      #doc.transparent(0.5) { doc.stroke_bounds }
      doc.text(Option.string(Option::Keys::WEBSITE_NAME),
               align: :center,
               overflow: :shrink_to_fit,
               size: 18)
    end
    doc.move_down(24)

    # URL
    url = item_url(item, Rails.application.config.action_controller.default_url_options)
    doc.text("<link href='#{url}'>#{url}</link>",
             inline_format: true,
             align: :center)
    doc.move_down(24)

    # Download date
    doc.text("Downloaded on #{Time.now.strftime("%B %e, %Y")}", align: :center)
  end

  ##
  # @param item [Item] Parent item.
  # @param items [Enumerable<Item>] All items in the document.
  #
  def create_outline(item, items, doc)
    doc.outline.define do |outline|
      outline.section(item.title, destination: 1) do
        outline.page(title: "Title Page", destination: 1)
        items.each_with_index do |item, index|
          outline.page(title: item.title, destination: 2 + index)
        end
      end
    end
  rescue NoMethodError
    # TODO: why does Prawn sometimes do this?
    # NoMethodError: undefined method `dictionary' for nil:NilClass
  end

  ##
  # Downloads an image binary in a PDF-optimized format and adds it to the
  # given PDF document.
  #
  # @param binary [Binary]
  # @param doc [Prawn::Document]
  #
  def draw_item_page(binary, doc)
    if !binary.is_image?
      LOGGER.debug('add_image(): %s is not an image; skipping.', binary)
      return
    elsif !binary.image_server_safe?
      LOGGER.debug('add_image(): %s will bog down the image server; skipping.',
                   binary)
      return
    end

    draw_word_boxes(binary, doc)

    # Download an optimally-sized JPEG derivative image to a temp file.
    width    = IMAGE_DPI / DOCUMENT_PPI.to_f * doc.bounds.width
    height   = IMAGE_DPI / DOCUMENT_PPI.to_f * doc.bounds.height
    if binary.width && binary.height # should always be true
      width  = binary.width if width > binary.width
      height = binary.height if height > binary.height
    else
      width  = -1
      height = -1
    end
    pathname = download_image(binary, width, height)

    # Append it to the document.
    doc.image(pathname,
              position:  :center,
              vposition: :center,
              fit:       [doc.bounds.width, doc.bounds.height])
  end

  ##
  # Adds text boxes containing OCRed words, if available, in order to make the
  # document searchable.
  #
  def draw_word_boxes(binary, doc)
    return if binary.tesseract_json.blank?

    box_padding  = 6 # helps to avoid Prawn::Errors::CannotFit
    doc_width    = PAGE_WIDTH_INCHES * DOCUMENT_PPI
    doc_height   = PAGE_HEIGHT_INCHES * DOCUMENT_PPI
    x_scale      = doc.bounds.width / binary.width.to_f
    y_scale      = doc.bounds.height / binary.height.to_f
    canvas_scale = [x_scale, y_scale].min
    img_width    = binary.width * canvas_scale
    img_height   = binary.height * canvas_scale
    x_offset     = (doc.bounds.width - img_width) / 2.0
    y_offset     = (doc.bounds.height - img_height) / 2.0
    LOGGER.debug('add_image(): [page: %dx%d] [doc bounds: %dx%d] '\
                 '[full image: %dx%d] [scaled image: %dx%d] [word offset: %d,%d]',
                 doc_width, doc_height,
                 doc.bounds.width, doc.bounds.height,
                 binary.width, binary.height,
                 img_width, img_height,
                 x_offset, y_offset)

    struct  = JSON.parse(binary.tesseract_json)
    struct['text'].each_with_index do |word, word_index|
      next if word.blank?
      x      = struct['left'][word_index] * canvas_scale + x_offset - box_padding / 2.0
      y      = doc.bounds.height - struct['top'][word_index] * canvas_scale - y_offset + box_padding / 2.0
      width  = struct['width'][word_index] * canvas_scale + box_padding
      height = struct['height'][word_index] * canvas_scale + box_padding
      begin
        doc.text_box(word,
                     at:       [x, y],
                     width:    width,
                     height:   height,
                     overflow: :shrink_to_fit) # truncate, shrink_to_fit, expand
      rescue Prawn::Errors::CannotFit
        LOGGER.warn("draw_word_boxes(): can't fit: #{x},#{y}/#{width}x#{height}")
      end
    end
  end

  ##
  # Downloads an appropriate image to a temp file, which will be located in
  # {image_temp_dir}.
  #
  # @param binary [Binary]
  # @param width [Integer]
  # @param height [Integer]
  # @return [String] Temp file path.
  #
  def download_image(binary, width, height)
    width    = width.to_i
    height   = height.to_i
    size     = (width > 0) ? "!#{width},#{height}" : 'max'
    url      = "#{binary.iiif_image_url}/full/#{size}/0/default.jpg"
    pathname = File.join(
      image_temp_dir,
      binary.filename.split('.')[0...-1].join('.') + '.jpg')
    File.open(pathname, 'wb') do |file|
      LOGGER.debug('download_image(): downloading %s to %s', url, pathname)
      ImageServer.instance.client.get_content(url) do |chunk|
        file.write(chunk)
      end
    end
    pathname
  end

  ##
  # @param item [Item] Compound object.
  # @return [Prawn::Document]
  #
  def new_pdf_document(item)
    pdf = Prawn::Document.new(
        margin: MARGIN_INCHES * DOCUMENT_PPI,
        info: {
            Title: item.title,
            Author: item.element(:creator).to_s,
            #Subject: '',
            #Keywords: '',
            Creator: Option::string(Option::Keys::WEBSITE_NAME),
            Producer: 'Prawn',
            CreationDate: Time.now
        })
    pdf.default_leading 2
    pdf
  end

  ##
  # @return [String] Temporary directory for images downloaded from the image
  #                  server.
  #
  def image_temp_dir
    unless @image_temp_dir && Dir.exist?(@image_temp_dir)
      @image_temp_dir = Dir.mktmpdir
    end
    @image_temp_dir
  end

  ##
  # @return [String] Pathname of the generated PDF.
  #
  def pdf_temp_file
    unless @pdf_temp_file && File.exist?(@pdf_temp_file)
      @pdf_temp_file = Tempfile.new('item.pdf-')
    end
    @pdf_temp_file
  end

  def reset
    @image_temp_dir = @pdf_temp_file = nil
  end

end