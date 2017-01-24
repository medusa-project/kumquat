##
# Controller for the OAI-PMH endpoint.
#
# @see http://www.openarchives.org/OAI/openarchivesprotocol.html
#
class OaiPmhController < ApplicationController

  include OaiPmhHelper

  protect_from_forgery with: :null_session

  before_action :check_pmh_enabled
  before_action :validate_request

  MAX_LIST_RESULTS = 100
  SUPPORTED_METADATA_FORMATS = %w(oai_dc oai_qdc)

  def initialize
    super
    @errors = [] # list of hashes with 'code' and 'description' keys
  end

  def index
    @host = request.host_with_port
    @metadata_format = params[:metadataPrefix]
    response.content_type = 'text/xml'

    template = nil
    case params[:verb]
      when 'GetRecord' # 4.1
        template = do_get_record
      when 'Identify' # 4.2
        template = do_identify
      when 'ListIdentifiers' # 4.3
        template = do_list_identifiers
      when 'ListMetadataFormats' # 4.4
        template = do_list_metadata_formats
      when 'ListRecords' # 4.5
        template = do_list_records
      when 'ListSets' # 4.6
        template = do_list_sets
      when nil
        @errors << { code: 'badVerb', description: 'Missing verb argument.' }
      else
        @errors << { code: 'badVerb', description: 'Illegal verb argument.' }
    end
    template = 'error.xml.builder' if @errors.any?
    render template
  end

  protected

  def do_get_record
    if params[:identifier].blank?
      @errors << { code: 'badArgument',
                   description: 'Missing identifier argument.' }
    else
      @item = item_for_oai_pmh_identifier(params[:identifier], @host)
      if @item
        @identifier = oai_pmh_identifier_for(@item, @host)
      else
        @errors << { code: 'idDoesNotExist',
                     description: 'The value of the identifier argument is '\
                         'unknown or illegal in this repository.' }
      end
    end
    if @metadata_format.blank?
      @errors << { code: 'badArgument',
                   description: 'Missing metadataPrefix argument.' }
    elsif !SUPPORTED_METADATA_FORMATS.include?(@metadata_format)
      @errors << { code: 'cannotDisseminateFormat',
                   description: 'The metadata format identified by the '\
                       'metadataPrefix argument is not supported by this '\
                       'object.' }
    end
    'get_record.xml.builder'
  end

  def do_identify
    items = Item.order(created_at: :asc).limit(1)
    @earliest_datestamp = items.any? ? items.first.created_at.utc.iso8601 : nil
    'identify.xml.builder'
  end

  def do_list_identifiers
    @results = preprocessing_for_list_identifiers_or_records
    'list_identifiers.xml.builder'
  end

  def do_list_metadata_formats
    if params[:identifier]
      @item = item_for_oai_pmh_identifier(params[:identifier], @host)
      @errors << { code: 'idDoesNotExist',
                   description: 'The value of the identifier argument is '\
                       'unknown or illegal in this repository.' } unless @item
    end
    'list_metadata_formats.xml.builder'
  end

  def do_list_records
    @results = preprocessing_for_list_identifiers_or_records
    'list_records.xml.builder'
  end

  def do_list_sets
    @results = Collection.
        where(published: true, published_in_dls: true, harvestable: true).
        order(:repository_id)
    @total_num_results = @results.count
    @results_offset = offset
    @results = @results.offset(@results_offset)
    @next_page_available =
        (@results_offset + MAX_LIST_RESULTS < @total_num_results)
    @expiration_date = resumption_token_expiration_date
    @results.limit(MAX_LIST_RESULTS)
    'list_sets.xml.builder'
  end

  private

  def check_pmh_enabled
    render text: 'This server\'s OAI-PMH endpoint is disabled.',
           status: :service_unavailable unless
        Option::boolean(Option::Key::OAI_PMH_ENABLED)
  end

  ##
  # @return [Integer]
  #
  def offset
    if params[:resumptionToken].present?
      params[:resumptionToken].split(';').each do |pair|
        kv = pair.split(':')
        return kv[1].to_i if kv.length == 2 and kv[0] == 'offset'
      end
    end
    0
  end

  def preprocessing_for_list_identifiers_or_records
    if @metadata_format.blank?
      @errors << { code: 'badArgument',
                   description: 'Missing metadataPrefix argument.' }
    elsif !SUPPORTED_METADATA_FORMATS.include?(@metadata_format)
      @errors << { code: 'cannotDisseminateFormat',
                   description: 'The metadata format identified by '\
                           'the metadataPrefix argument is not supported by '\
                           'this repository.' }
    end

    @results = Item.joins('LEFT JOIN collections ON collections.repository_id '\
            '= items.collection_repository_id').
        where('collections.harvestable': true,
              'collections.published': true,
              'collections.published_in_dls': true,
              published: true).
        order(created_at: :asc)

    from = to = Time.now
    from = Time.parse(params[:from]).utc.iso8601 if params[:from]
    to = Time.parse(params[:until]).utc.iso8601 if params[:until]
    if from != to
      @results = @results.where('items.created_at > ?', from).
          where('items.created_at < ?', to)
    end
    if params[:set]
      @results = @results.where(collection_repository_id: params[:set])
    end

    @errors << { code: 'noRecordsMatch',
                 description: 'No matching records.' } unless @results.any?

    @total_num_results = @results.count
    @results_offset = offset
    @results = @results.offset(@results_offset)
    @next_page_available =
        (@results_offset + MAX_LIST_RESULTS < @total_num_results)
    @resumption_token = resumption_token(@results_offset)
    @expiration_date = resumption_token_expiration_date
    @results.limit(MAX_LIST_RESULTS)
  end

  ##
  # @param current_offset [Integer]
  # @return [String]
  #
  def resumption_token(current_offset)
    "offset:#{current_offset + MAX_LIST_RESULTS}"
  end

  def resumption_token_expiration_date
    (Time.now + 1.hour).utc.iso8601
  end

  def validate_request
    # POST requests must have a Content-Type of
    # application/x-www-form-urlencoded (3.1.1.2)
    if request.method == 'POST' and
        request.content_type != 'application/x-www-form-urlencoded'
      @errors << {
          code: 'badArgument',
          description: 'Content-Type of POST requests must be '\
          '"application/x-www-form-urlencoded"'
      }
    end
  end

end
