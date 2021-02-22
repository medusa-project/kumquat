##
# Downloads images from the IIIF image server and assembles them into a PDF.
#
# @see http://prawnpdf.org/manual.pdf
#
class IiifPdfGenerator

  LOGGER = CustomLogger.new(IiifPdfGenerator)

  DOCUMENT_DPI       = 72 # This is maintained by Prawn and should not be changed here.
  IMAGE_DPI          = 150
  MARGIN_INCHES      = 0.5
  PAGE_WIDTH_INCHES  = 8.5
  PAGE_HEIGHT_INCHES = 11

  ##
  # Assembles the {Binary#public public} access master image binaries of all of
  # a compound object's child items into a PDF.
  #
  # @param item [Item] Compound object.
  # @param include_private_binaries [Boolean]
  # @param task [Task] Optional; supply to receive progress updates.
  # @return [String, nil] Pathname of the generated PDF, or nil if there are no
  #                       images to add to the PDF.
  #
  def generate_pdf(item:, include_private_binaries: false, task: nil)
    reset
    children = item.search_children.to_a
    if children.any?
      doc   = pdf_document(item)
      count = children.count
      children.each_with_index do |child, child_index|
        task&.progress = child_index / count.to_f

        binaries = child.binaries.where(
            master_type:    Binary::MasterType::ACCESS,
            media_category: Binary::MediaCategory::IMAGE)
        binaries = binaries.where(public: true) unless include_private_binaries
        binaries.each do |binary|
          doc.start_new_page if child_index > 0
          add_image(binary, doc)
        end
      end
      pathname = pdf_temp_file
      doc.render_file(pathname)

      FileUtils.rm_rf(image_temp_dir)

      return pathname
    else
      LOGGER.info('generate_pdf(): %s has no child items.', item)
    end
    nil
  end

  private

  ##
  # Downloads an image binary in a PDF-optimized format and adds it to the
  # given PDF document.
  #
  # @param binary [Binary]
  # @param doc [Prawn::Document]
  # @return [String] Pathname of the converted image.
  #
  def add_image(binary, doc)
    if binary.is_image?
      if binary.image_server_safe?
        # Download an optimally-sized JPEG derivative of image to a temp file.
        hres = IMAGE_DPI / DOCUMENT_DPI.to_f * doc.bounds.width
        vres = IMAGE_DPI / DOCUMENT_DPI.to_f * doc.bounds.height
        LOGGER.debug('add_image(): [document: %dx%d] [image box: %dx%d]',
            doc.bounds.width, doc.bounds.height, hres, vres)

        url = "#{binary.iiif_image_url}/full/!#{hres.to_i},#{vres.to_i}/0/default.jpg"

        image_pathname = File.join(
            image_temp_dir,
            binary.filename.split('.')[0...-1].join('.') + '.jpg')

        File.open(image_pathname, 'wb') do |file|
          LOGGER.info('add_image(): downloading %s to %s',
                      url, image_pathname)
          ImageServer.instance.client.get_content(url) do |chunk|
            file.write(chunk)
          end
        end

        doc.image(image_pathname,
                  position: :center,
                  vposition: :center,
                  fit: [doc.bounds.width, doc.bounds.height])

        return image_pathname
      else
        LOGGER.debug('add_image(): %s will bog down the image server; skipping.',
                     binary)
      end
    else
      LOGGER.debug('add_image(): %s is not an image; skipping.', binary)
    end
  end

  ##
  # @param item [Item] Compound object.
  # @return [Prawn::Document]
  #
  def pdf_document(item)
    pdf = Prawn::Document.new(
        margin: MARGIN_INCHES * 72, # 1 inch = 72 points
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
      @pdf_temp_file = Tempfile.new('item.pdf-').path
    end
    @pdf_temp_file
  end

  def reset
    @image_temp_dir = @pdf_temp_file = nil
  end

end