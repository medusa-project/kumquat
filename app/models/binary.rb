##
# Represents a file stored in Medusa. Almost all binaries are attached to
# {Item}s, but there may be a few that aren't (ones that are used to represent
# collections, for example).
#
# Binaries have a many-to-one relationship with {Item}s. When an item is
# deleted, so are all of its binaries.
#
# Binaries are commonly obtained via {Binary#from_medusa_file}.
#
# Binary data is accessible via {data}, which returns a stream of data from the
# repository S3 bucket.
#
# A binary may have a {MasterType master type}. {MasterType::PRESERVATION
# Preservation masters} are typically in a preservation-optimized format/
# encoding, and {MasterType::ACCESS access masters} are typically a variant of
# the preservation master that may be smaller, more compatible with an image
# server or client viewer software, etc.
#
# A binary has a media (MIME) type, which may be different from the Medusa
# file's media type (which tends to be vague). When the two differ, the
# Binary's media type is usually more specific.
#
# A binary may also reside in a {MediaCategory media category}, which helps to
# differentiate binaries that have the same media type but different uses.
# This is relevant in collections that use the
# {PackageProfile::MIXED_MEDIA_PROFILE Mixed Media package profile}, whose
# items may have a representative `image/jpeg` binary as well as an
# `image/jpeg` 3D model texture.
#
# Access master images can are served via the image server. Their {medusa_uuid}
# property is used as their IIIF ID. When it receives a request, the image
# server queries Medusa for the S3 key of the file corresponding to that UUID.
#
# # Attributes
#
# * `byte_size`      Size of the binary's contents in bytes.
# * `medusa_uuid`    UUID of the binary's corresponding file in Medusa.
# * `created_at`     Managed by ActiveRecord.
# * `duration`       Duration of audio/video, in seconds.
# * `full_text`      Full text from OCR.
# * `height`         Native pixel height of a raster binary (image or video).
# * `hocr`           OCR data in hOCR format. This may be blank with
#                    {tesseract_json} being used instead, depending on
#                    environment.
# * `item_id`        Database ID of the binary's owning item.
# * `master_type`    One of the {MasterType} constant values.
# * `media_category` One of the {MediaCategory} constant values.
# * `media_type`     Best-fit IANA media (MIME) type.
# * `metadata_json`  Embedded EXIF/IPTC/XMP metadata serialized as JSON. See
#                    {read_metadata} for documentation of the structure.
#                    Typically the metadata would be accessed via {metadata}
#                    and not directly from this ivar.
# * `object_key`     S3 object key.
# * `ocred_at`       The last time that OCR was run on the binary. This is a
#                    more reliable way of knowing whether OCR has been run than
#                    checking for a non-empty {full_text} value, because that
#                    may be empty in the case of e.g. blank pages.
# * `public`         Whether the binary is publicly accessible. If false, the
#                    binary cannot be viewed or downloaded. This is superseded
#                    by {Collection#publicize_binaries} which, if `false`,
#                    means that the binary is not publicly accessible
#                    regardless of how this property is set. (N.B.: {public?}
#                    takes this into account.)
# * `tesseract_json` OCR data returned from
#                    [tesseract-lambda](https://github.com/medusa-project/tesseract-lambda)
#                    via {detect_text}, serialized as JSON. This may be blank
#                    with {hocr} being used instead, depending on environment.
# * `updated_at`     Managed by ActiveRecord.
# * `width`          Native pixel width of a raster binary (image or video).
#
class Binary < ApplicationRecord

  ##
  # Must be kept in sync with the return value of {Binary#human_readable_master_type()}.
  #
  class MasterType
    ACCESS       = 1
    PRESERVATION = 0
  end

  ##
  # Broad category in which a binary can be considered to reside. This may be
  # different from the one in `media_type`; for example, the main image and a
  # 3D model texture may both be JPEGs, but be in different categories, and
  # when displaying an image viewer, we want to select the main image, and not
  # a texture.
  #
  class MediaCategory
    AUDIO    = 3
    BINARY   = 5
    IMAGE    = 0
    DOCUMENT = 1
    TEXT     = 6
    THREE_D  = 4
    VIDEO    = 2

    ##
    # @param media_type [String]
    # @return [Integer, nil] MediaCategory constant value best fitting the
    #                        given media type; or nil.
    #
    def self.media_category_for_media_type(media_type)
      case media_type
        when 'image/vnd.adobe.photoshop'
          return IMAGE
        when 'text/plain'
          return TEXT
      end
      # TODO: this code finds the first but not necessarily best match, which is the reason for the override above.
      formats = Binary.class_variable_get(:'@@formats')
      formats = formats.select{ |f| f['media_types'].include?(media_type) }
      formats.any? ? formats.first['media_category'] : nil
    end
  end

  LOGGER                      = CustomLogger.new(Binary)
  DEFAULT_MEDIA_TYPE          = 'unknown/unknown'
  TESSERACT_SUPPORTED_FORMATS = %w(image/jpeg image/png image/tiff)

  # touch: true means when the instance is saved, the owning item's updated_at
  # property will be updated.
  belongs_to :item, inverse_of: :binaries, touch: true, optional: true

  validates :byte_size, numericality: { only_integer: true,
                                        greater_than_or_equal_to: 0 },
            allow_blank: false
  validates :object_key, length: { allow_blank: false }

  @@formats = YAML::load(File.read("#{Rails.root}/lib/formats.yml"))

  ##
  # @param file [Medusa::File]
  # @param master_type [Integer]    One of the {Binary::MasterType} constant
  #                                 values.
  # @param media_category [Integer] One of the {Binary::MediaCategory} constant
  #                                 values. If nil, will be inferred from the
  #                                 media type.
  # @return [Binary] Fully initialized instance. May be a new instance or an
  #                  existing one, but either way, it may contain changes that
  #                  have not been persisted.
  #
  def self.from_medusa_file(file, master_type, media_category = nil)
    bin = Binary.find_by_object_key(file.relative_key) || Binary.new
    bin.master_type = master_type
    bin.medusa_uuid = file.uuid
    bin.object_key  = file.relative_key
    bin.byte_size   = file.size
    # The media type of the file as reported by Medusa is likely to be vague,
    # so let's see if we can do better.
    bin.infer_media_type
    bin.media_category = media_category ||
        Binary::MediaCategory::media_category_for_media_type(bin.media_type)
    bin.read_duration
    bin.read_metadata
    bin
  end

  ##
  # @return [IO] Read-only stream of the instance's data.
  #
  def data
    client = MedusaS3Client.instance
    response = client.get_object(bucket: MedusaS3Client::BUCKET,
                                 key:    self.object_key)
    response.body
  end

  ##
  # @return [String]
  # @see https://www.dublincore.org/specifications/dublin-core/dcmi-type-vocabulary/
  #
  def dc_type
    type = nil
    if self.is_3d?
      type = 'PhysicalObject'
    elsif self.is_image?
      type = 'StillImage'
    elsif self.is_video?
      type = 'MovingImage'
    elsif self.is_audio?
      type = 'Sound'
    elsif self.is_pdf? || self.is_text?
      type = 'Text'
    end
    type
  end

  ##
  # Runs OCR against the binary.
  #
  # @raises [RuntimeError] if the instance is not {ocrable?}.
  #
  def detect_text
    raise 'This instance does not support OCR.' unless self.ocrable?
    if Rails.env.development? || Rails.env.test?
      #detect_text_using_local_tesseract
      detect_text_using_lambda_ocr
    else
      detect_text_using_lambda_ocr
    end
  end

  ##
  # @return [String, nil] The filename portion of `object_key`.
  #
  def filename
    File.basename(self.object_key)
  end

  ##
  # @return [String]
  #
  def human_readable_master_type
    case self.master_type
    when MasterType::ACCESS
      return 'Access Master'
    when MasterType::PRESERVATION
      return 'Preservation Master'
    end
    nil
  end

  ##
  # @return [String]
  #
  def human_readable_media_category
    case self.media_category
      when MediaCategory::AUDIO
        return 'Audio'
      when MediaCategory::BINARY
        return 'Binary'
      when MediaCategory::IMAGE
        return 'Image'
      when MediaCategory::DOCUMENT
        return 'Document'
      when MediaCategory::TEXT
        return 'Text'
      when MediaCategory::THREE_D
        return '3D'
      when MediaCategory::VIDEO
        return 'Video'
    end
    nil
  end

  ##
  # @return [String]
  #
  def human_readable_name
    name = nil
    formats = @@formats.select{ |f| f['media_types'].include?(self.media_type) }
    if formats.any?
      name = formats.first['label']
    end
    if name.blank?
      name = self.media_type
    end
    if name.blank?
      name = 'Unknown Type'
    end
    name
  end

  ##
  # If the instance is attached to an Item that has an embed tag that refers
  # to a video in [UI MediaSpace](https://mediaspace.illinois.edu), parts of
  # the URL in its `src` attribute are extracted in order to construct an
  # identifier that the image server will recognize as an image it should serve
  # from there.
  #
  # Otherwise, the Medusa file UUID is returned.
  #
  # This is, of course, an ugly hack and we would be better off getting video
  # stills quickly out of an S3 bucket, if we could.
  #
  # @return [String] Image server identifier of the instance.
  #
  def iiif_image_identifier
    if is_media_space_video?
      matches = self.item.embed_tag.match(/src="(.*?)"/)
      if matches
        video_url = matches[0][5..matches[0].length - 2]
        bits = video_url.match(/\/p\/(\d+)\/sp\/(\d+)\/.*&entry_id=([A-Za-z0-9_]+)/).captures
        return (['v'] + bits[0..2]).join('/')
      end
    else
      self.medusa_uuid
    end
  end

  ##
  # @return [String] IIIF Image API v2 URI of the instance, regardless of
  #                  whether it is compatible with an image server.
  # @see image_server_safe?
  #
  def iiif_image_v2_url
    Configuration.instance.iiif_image_v2_url + '/' +
        CGI.escape(self.iiif_image_identifier)
  end

  ##
  # @return [String] IIIF Image API info.json URL.
  #
  def iiif_info_url
    self.iiif_image_v2_url + '/info.json'
  end

  ##
  # @return [Boolean] Whether the instance is presumed safe to feed through an
  #                   image server (won't bog it down too much).
  #
  def image_server_safe?
    if self.object_key.present?
      psd_types = %w(image/vnd.adobe.photoshop application/x-photoshop
          application/photoshop application/psd image/psd)
      if self.is_image? and !psd_types.include?(self.media_type)
        # Large TIFF files are probably neither tiled nor multiresolution, so
        # are going to bog down the image server in proportion to their size.
        max_tiff_size = 25000000
        if self.media_type == 'image/tiff' and
            self.byte_size and self.byte_size > max_tiff_size
          return false
        end
        return true
      elsif self.is_pdf? or self.is_media_space_video?
        return true
      end
    end
    false
  end

  ##
  # Tries to infer the media type of the instance. The first resort is to check
  # for a recognized extension in the object key, and the last resort (because
  # it is more expensive) is to read the first few bytes of the file and
  # attempt infer a media type from that.
  #
  # @raises [IOError] If the file doesn't exist or can't be read.
  #
  def infer_media_type
    ext = File.extname(self.object_key)
    if ext.present?
      # Add some workarounds for formats that require special handling.
      case ext.downcase
      when '.mp4', '.m4v'
        self.media_type = 'video/mp4'
      when '.mtl'
        self.media_type = 'text/plain'
      when '.obj'
        self.media_type = 'text/plain'
      end
    end
    if self.media_type.blank? || self.media_type == DEFAULT_MEDIA_TYPE
      # Try to infer the media type from the file header.
      # First, check the Content-Length response header in order to find the
      # end of the requestable range.
      client = MedusaS3Client.instance
      response = client.head_object(
          bucket: MedusaS3Client::BUCKET,
          key:    self.object_key)
      end_pos = [20, response.content_length].min
      if end_pos > 2
        response = client.get_object(
            bucket: MedusaS3Client::BUCKET,
            key:    self.object_key,
            range:  "bytes=0-#{end_pos}")
        self.media_type = MimeMagic.by_magic(response.body)
      end
      # If that failed, fall back to inferring it from the filename extension.
      if self.media_type.blank? || self.media_type == DEFAULT_MEDIA_TYPE
        self.media_type = MimeMagic.by_extension(ext)&.type
      end
    end
  end

  def is_3d?
    (self.media_category == MediaCategory::THREE_D)
  end

  def is_audio?
    self.media_type && self.media_type.start_with?('audio/')
  end

  def is_document?
    (self.media_category == MediaCategory::DOCUMENT)
  end

  def is_image?
    self.media_type && self.media_type.start_with?('image/')
  end

  ##
  # @return [Boolean] Whether the binary is a video and a version of it resides
  #                   in [UI MediaSpace](https://mediaspace.illinois.edu).
  #
  def is_media_space_video?
    is_video? and self.item&.embed_tag&.include?('kaltura')
  end

  def is_pdf? # TODO: replace with is_document?()
    self.media_type and self.media_type == 'application/pdf'
  end

  ##
  # @return [Boolean] Whether the binary is of a still or moving raster image
  #                   (video) with pixel dimensions.
  #
  def is_raster?
    is_image? or is_video?
  end

  ##
  # @return [Boolean] Whether the binary is plain text.
  #
  def is_text?
    self.media_type and self.media_type.start_with?('text/plain')
  end

  def is_video?
    self.media_type and self.media_type.start_with?('video/')
  end

  ##
  # @return [Medusa::File] See the documentation for the medusa-client gem.
  #
  def medusa_file
    @medusa_file = Medusa::File.with_uuid(self.medusa_uuid) unless @medusa_file
    @medusa_file
  end

  ##
  # @return [String, nil] URI of the binary's equivalent Medusa file.
  #
  def medusa_url
    url = nil
    if self.medusa_uuid.present?
      url = Configuration.instance.medusa_url.chomp('/') + '/uuids/' +
          self.medusa_uuid
    end
    url
  end

  ##
  # Provides access to embedded EXIF/IPTC/XMP metadata. Note that this does
  # not actually {read_metadata read the metadata}--it only deserializes and
  # returns what is stored in the database.
  #
  # @return [Enumerable<Hash<Symbol,String>>] Array of hashes with `:label`,
  #                                           `:category`, and `:value` keys.
  # @raises [IOError] If the file is not found or can't be read.
  #
  def metadata
    unless @deserialized_metadata
      @deserialized_metadata = self.metadata_json.present? ?
                                 JSON.parse(self.metadata_json, symbolize_names: true) : []
    end
    @deserialized_metadata
  end

  ##
  # @return [Boolean] Whether the instance is of a type that can be
  #                   {detect_text OCRed}. (Format conversion may still be
  #                   necessary.)
  #
  def ocrable?
    # N.B.: these conditions must be kept in sync with OcrCollectionJob and
    # OcrItemJob.
    self.master_type == Binary::MasterType::ACCESS &&
      (self.is_image? || self.is_pdf?)
  end

  ##
  # @return Whether the instance is publicly accessible--i.e. both {public} and
  #         the owning collection's {Collection#publicize_binaries} property
  #         are set to `true`.
  #
  def public?
    if self.public
      if self.item&.collection
        return self.item.collection.publicize_binaries
      end
      return true
    end
    false
  end

  ##
  # Populates the duration property by reading it from the source audio or
  # video.
  #
  # This is very, very, VERY expensive as the entire source file has to be
  # downloaded from S3.
  #
  # @return [void]
  # @raises [IOError] If the file does not exist.
  #
  def read_duration
    if is_audio? or is_video?
      begin
        # Download the image to a temp file.
        tempfile = Tempfile.new('image')
        download_to(tempfile.path)

        # Redirect ffprobe stderr output to stdout.
        output = `ffprobe "#{tempfile.path.gsub('"', '\\"')}" 2>&1`
        result = output.match(/Duration: [0-9][0-9]:[0-5][0-9]:[0-5][0-9]/)
        if result and result.length > 0
          begin
            self.duration = TimeUtils.hms_to_seconds(result[0].gsub('Duration: ', ''))
          rescue ArgumentError => e
            LOGGER.warn('read_duration(): %s', e)
          end
        end
      ensure
        tempfile.close
        tempfile.unlink
      end
    end
  end

  ##
  # Reads the binary's dimensions and embedded metadata.
  #
  # @raises [IOError] If the file is not found or can't be read.
  #
  def read_metadata
    return unless self.is_image?
    begin
      tempfile = Tempfile.new('image')
      # For performance and I/O cost reasons, we download only a small portion
      # of the beginning of the image.
      download_to(tempfile.path, 2 ** 18)

      read_metadata_using_exiv2(tempfile.path)
    ensure
      tempfile.close
      tempfile.unlink
    end
  end

  def to_param
    medusa_uuid
  end

  ##
  # @return [String] The instance's object key, or its Medusa file UUID, or the
  #                  return value of super -- whichever is present first.
  #
  def to_s
    str = self.object_key
    str = self.medusa_uuid if str.blank?
    str = super if str.blank?
    str
  end

  ##
  # @return [String] The URI of the corresponding S3 object.
  #
  def uri
    "s3://#{Configuration.instance.medusa_s3_bucket}/#{self.object_key}"
  end

  ##
  # Returns a list of rectangle coordinates and dimensions within the OCR data
  # (either {tesseract_json} or {hocr}) for all matches for the given word or
  # phrase.
  #
  # @param word_or_phrase [String]
  # @return [Enumerable<Hash<Symbol,Integer>>] Enumerable of hashes with `:x`,
  #         `:y`, `:width`, and `:height` keys.
  #
  def word_coordinates(word_or_phrase)
    if self.tesseract_json.present?
      return word_coordinates_from_tesseract(word_or_phrase)
    elsif self.hocr.present?
      return word_coordinates_from_hocr(word_or_phrase)
    end
  end


  private

  ##
  # Populates the {hocr} and {full_text} attributes using `tesseract` command
  # invocations.
  #
  def detect_text_using_local_tesseract
    Dir.mktmpdir do |tmpdir|
      if TESSERACT_SUPPORTED_FORMATS.include?(self.media_type)
        Tempfile.new do |file|
          client = MedusaS3Client.instance
          client.get_object(bucket: ::Configuration.instance.medusa_s3_bucket,
                            key:    self.object_key,
                            target: file)
        end
      else
        jpg_path = IiifImageConverter.new.convert_binary(self, tmpdir, :jpg)
      end
      self.full_text = `tesseract #{jpg_path} stdout`
      self.hocr      = `tesseract #{jpg_path} stdout hocr`
      self.ocred_at  = Time.now
      self.save!
    end
  end

  NUM_LAMBDA_TRIES = 2

  ##
  # Populates the {tesseract_json} and {full_text} attributes using an
  # invocation of a
  # [tesseract-lambda](https://github.com/medusa-project/tesseract-lambda)
  # function.
  #
  # @param num_tries [Integer] Used internally--ignore.
  #
  def detect_text_using_lambda_ocr(num_tries = 1)
    config = ::Configuration.instance
    client = Aws::Lambda::Client.new(region: config.aws_region,
                                     http_read_timeout: 120)

    payload = {
      bucket: config.medusa_s3_bucket,
      key:    self.object_key
    }

    begin
      response = client.invoke(
        function_name:   config.lambda_ocr_function,
        invocation_type: 'RequestResponse',
        log_type:        'None',
        payload:         JSON.generate(payload))

      if response.status_code == 200
        response_payload    = JSON.parse(response.payload.string)
        self.tesseract_json = response_payload['body']
        if self.tesseract_json.present?
          struct = JSON.parse(self.tesseract_json)
          self.full_text = struct['text'].join(' ')
        end
        self.ocred_at = Time.now
        self.save!
      else
        raise IOError, "#{config.lambda_ocr_function} returned status "\
              "#{response.status_code}"
      end
    rescue Seahorse::Client::NetworkingError, Net::ReadTimeout => e
      if num_tries < NUM_LAMBDA_TRIES
        detect_text_using_lambda_ocr(num_tries + 1)
      else
        raise e
      end
    end
  end

  def download_to(pathname, length = 0)
    # Use the smaller of the actual length or the requested length.
    length = [length, byte_size].min

    MedusaS3Client.instance.get_object(
        bucket:          MedusaS3Client::BUCKET,
        key:             self.object_key,
        response_target: pathname,
        range:           (length > 0) ? "bytes=#{0}-#{length}" : nil)
  end

  ##
  # Reads the contents of `pathname` into {metadata_json}. The instance is not
  # saved.
  #
  # @param pathname [String]
  #
  def read_metadata_using_exiv2(pathname)
    pathname = pathname.gsub('"', '\\"')

    # Read dimensions
    # Redirect stderr to /dev/null as there is apparently no other way to
    # suppress "no exif data found in the file" messages.
    output = `exiv2 "#{pathname}" 2> /dev/null`
    output.encode('UTF-8', invalid: :replace).split("\n").each do |row|
      next unless row.downcase.start_with?('image size')
      columns = row.split(':')
      if columns.length > 1
        dimensions = columns[1].split('x')
        if dimensions.length == 2
          self.width  = dimensions[0].strip.to_i
          self.height = dimensions[1].strip.to_i
        end
      end
    end

    # Read metadata
    metadata = []
    output   = `exiv2 -q -Pklt "#{pathname}"`
    output.encode('UTF-8', invalid: :replace).split("\n").each do |row|
      next if row.length < 10

      first_space = row.index(' ')
      col_2_start = first_space
      begin
        row[first_space..row.length - 1].split('').each_with_index do |char, index|
          if char != ' '
            col_2_start += index
            break
          end
        end
      rescue ArgumentError => e
        next if "#{e}".include?('bad value for range')
      end
      key = row[0..first_space - 1]

      next if key.start_with?('Exif.Thumbnail')
      next if key.start_with?('Xmp.xmpMM.DerivedFrom')
      next if key.start_with?('Xmp.xmpMM.History')

      cols = [key] + row[col_2_start..row.length - 1].gsub('  ', "\t").
          squeeze("\t").split("\t")

      value = cols[2]&.strip
      if value.present?
        value = value.gsub(/lang=\".*\" /, '')
        label = cols[1].strip
        category = key.split('.').first.upcase
        
        md = metadata.select{ |m| m[:category] == category && m[:label] == label }
        if md.any?
          unless md.first[:value].respond_to?(:each)
            md.first[:value] = [ md.first[:value] ]
          end
          md.first[:value] << value
        else
          metadata << { label: label, category: category, value: value }
        end
      end
    end
    self.metadata_json = JSON.generate(metadata)
  end

  def word_coordinates_from_hocr(word_or_phrase)
    # hOCR format includes punctuation. We want to do a punctuation-free,
    # case-insensitive search of only words.
    filter_regex   = /[^\w]/
    word_or_phrase = word_or_phrase.downcase
    doc            = Nokogiri::HTML.parse(self.hocr)
    results        = []
    word_or_phrase.split(/\s+/).each do |word|
      word.gsub!(filter_regex, '')
      doc.xpath("//span[@class='ocrx_word']").each do |node|
        if node.text.downcase.gsub(filter_regex, '') == word
          parts = node['title'].split(' ')
          x1    = parts[1].to_i
          y1    = parts[2].to_i
          x2    = parts[3].to_i
          y2    = parts[4].chomp(';').to_i
          results << { x: x1, y: y1, width: x2 - x1, height: y2 - y1 }
        end
      end
    end
    results
  end

  def word_coordinates_from_tesseract(word_or_phrase)
    filter_regex      = /[^\w]/
    word_or_phrase    = word_or_phrase.downcase
    struct            = JSON.parse(self.tesseract_json)
    struct['text']    = struct['text'].map{ |t| t.gsub(filter_regex, '').downcase }
    results           = []
    search_words      = word_or_phrase.split(/\s+/)
    return results unless struct['text']

    struct['text'].each_with_index do |ocr_word, ocr_word_index|
      if search_words[0] == ocr_word
        match_start_index = ocr_word_index
        match_length      = 0
        search_words.each_with_index do |search_word, search_word_index|
          if search_word == struct['text'][ocr_word_index + search_word_index]
            match_length += 1
            if match_length == search_words.length
              (match_start_index..(ocr_word_index + search_word_index)).each do |i|
                results << {
                  x:      struct['left'][i],
                  y:      struct['top'][i],
                  width:  struct['width'][i],
                  height: struct['height'][i]
                }
              end
            end
          end
        end
      end
    end
    results
  end

end
