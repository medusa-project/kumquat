##
# Controller for the OAI-PMH endpoint.
#
# Identifier syntax:
#
# `oai:host:port:repository_id`
#
# Resumption token:
#
# The resumption token is ROT-18-encoded to make it appear opaque and
# discourage clients from changing it, even though if they do, it's not a big
# deal. The decoded format is:
#
# `set:n|from:n|until:n|start:n|metadataPrefix:n`
#
# Components can be in any order but the separators (colons and bars) are
# important.
#
# @see http://www.openarchives.org/OAI/openarchivesprotocol.html
# @see http://www.openarchives.org/OAI/2.0/guidelines-oai-identifier.htm
#
class OaiPmhController < ApplicationController

  include OaiPmhHelper

  protect_from_forgery with: :null_session

  before_action :check_pmh_enabled
  before_action :validate_request

  MAX_RESULT_WINDOW = 100
  RESUMPTION_TOKEN_COMPONENT_SEPARATOR = '|'
  RESUMPTION_TOKEN_KEY_VALUE_SEPARATOR = ':'
  SUPPORTED_METADATA_FORMATS = [
      {
          name: 'oai_dc',
          schema: 'http://www.openarchives.org/OAI/2.0/oai_dc.xsd',
          namespace: 'http://www.openarchives.org/OAI/2.0/oai_dc/'
      },
      {
          name: 'oai_dcterms',
          schema: 'http://dublincore.org/schemas/xmls/qdc/2008/02/11/dcterms.xsd',
          namespace: 'http://purl.org/dc/terms/'
      },
      {
          name: 'oai_qdc', # mix of "dc:" and "dcterms:" a la CONTENTdm
          schema: 'http://dublincore.org/schemas/xmls/qdc/2003/04/02/appqualifieddc.xsd',
          namespace: 'http://oclc.org/appqualifieddc/'
      }
  ]

  def initialize
    super
    @errors = [] # list of hashes with 'code' and 'description' keys
  end

  def index
    if @errors.any? # validate_request() may have added some
      template = 'error.xml.builder'
      render template
      return
    end

    @metadata_format = get_metadata_prefix
    @host = request.host_with_port
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

    @query = @errors.select{ |e| %w(badVerb badArgument).include?(e[:code]) }.any? ?
                 {} : params.except('controller', 'action').to_unsafe_hash

    template = 'error.xml.builder' if @errors.any?
    render template
  end

  protected

  def do_get_record
    @item = item_for_oai_pmh_identifier(params[:identifier], @host)
    if @item
      @identifier = oai_pmh_identifier_for(@item, @host)
    else
      @errors << { code: 'idDoesNotExist',
                   description: 'The value of the identifier argument is '\
                       'unknown or illegal in this repository.' }
    end
    'get_record.xml.builder'
  end

  def do_identify
    item = Item.order(created_at: :asc).limit(1).first
    @earliest_datestamp = item ? item.created_at.utc.iso8601 : nil
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
    @results = Collection.where(public_in_medusa: true,
                                published_in_dls: true,
                                harvestable: true).order(:repository_id)
    @total_num_results = @results.count
    @results_offset = get_start
    @results = @results.offset(@results_offset)
    @next_page_available =
        (@results_offset + MAX_RESULT_WINDOW < @total_num_results)
    @expiration_date = resumption_token_expiration_date
    @results.limit(MAX_RESULT_WINDOW)
    'list_sets.xml.builder'
  end

  private

  def check_pmh_enabled
    unless Option::boolean(Option::Keys::OAI_PMH_ENABLED)
      render plain: 'This server\'s OAI-PMH endpoint is disabled.',
             status: :service_unavailable
    end
  end

  ##
  # @return [String, nil] "From" from the resumptionToken, if present, or else
  #                       from the "from" argument.
  #
  def get_from
    parse_resumption_token('from') || params[:from]
  end

  ##
  # @return [String, nil] metadataPrefix from the resumptionToken, if present,
  #                       or else from the metadataPrefix argument.
  #
  def get_metadata_prefix
    parse_resumption_token('metadataPrefix') || params[:metadataPrefix]
  end

  ##
  # @return [String, nil] Set from the resumptionToken, if present, or else
  #                       from the set argument.
  #
  def get_set
    parse_resumption_token('set') || params[:set]
  end

  ##
  # @return [Integer] Start (a.k.a. offset) from the resumptionToken, or 0 if
  #                   the resumptionToken is not present.
  #
  def get_start
    parse_resumption_token('start')&.to_i || 0
  end

  ##
  # @return [String, nil] "Until" from the resumptionToken, if present, or else
  #                       from the "until" argument.
  #
  def get_until
    parse_resumption_token('until') || params[:until]
  end


  def parse_resumption_token(key)
    if params[:resumptionToken].present?
      decoded = StringUtils.rot18(params[:resumptionToken])
      decoded.split(RESUMPTION_TOKEN_COMPONENT_SEPARATOR).each do |component|
        kv = component.split(RESUMPTION_TOKEN_KEY_VALUE_SEPARATOR)
        return kv[1] if kv.length == 2 and kv[0] == key
      end
    end
    nil
  end

  def preprocessing_for_list_identifiers_or_records
    @results = Item.joins('LEFT JOIN collections ON collections.repository_id '\
            '= items.collection_repository_id').
        where('collections.harvestable': true,
              'collections.public_in_medusa': true,
              'collections.published_in_dls': true,
              published: true).
        where('collections.package_profile_id = ? OR items.parent_repository_id IS NULL',
              PackageProfile::FREE_FORM_PROFILE.id).
        where('items.variant IS NULL OR items.variant = \'\' OR items.variant = ?',
              Item::Variants::FILE).
        order(created_at: :asc)

    from = get_from
    from_time = nil
    from_time = Time.parse(from).utc.iso8601 if from
    to = get_until
    to_time = nil
    to_time = Time.parse(to).utc.iso8601 if to

    if from_time != to_time
      @results = @results.where('items.created_at >= ?', from_time).
          where('items.created_at <= ?', to_time)
    end

    set = get_set
    @results = @results.where(collection_repository_id: set) if set

    @errors << { code: 'noRecordsMatch',
                 description: 'No matching records.' } unless @results.any?

    @total_num_results = @results.count
    @results_offset = get_start
    @results = @results.offset(@results_offset)
    @next_page_available =
        (@results_offset + MAX_RESULT_WINDOW < @total_num_results)
    @resumption_token = resumption_token(set, from, to, @results_offset,
                                         @metadata_format)
    @expiration_date = resumption_token_expiration_date
    @results.limit(MAX_RESULT_WINDOW)
  end

  def resumption_token(set, from, until_, current_start, metadata_prefix)
    token = [
        ['set', set],
        ['from', from],
        ['until', until_],
        ['start', current_start + MAX_RESULT_WINDOW],
        ['metadataPrefix', metadata_prefix]
    ].
        select{ |a| a[1].present? }.
        map{ |a| a.join(RESUMPTION_TOKEN_KEY_VALUE_SEPARATOR) }.
        join(RESUMPTION_TOKEN_COMPONENT_SEPARATOR)
    StringUtils.rot18(token)
  end

  def resumption_token_expiration_date
    (Time.now + 1.hour).utc.iso8601
  end

  ##
  # @param required [Array<String>]
  # @param allowed [Array<String>]
  #
  def validate_arguments(required, allowed)
    params_hash = params.to_unsafe_hash

    # Ignore these
    ignore = %w(action controller verb)
    allowed -= ignore
    required -= ignore

    # Check that resumptionToken is an exclusive argument.
    if params_hash.keys.include?('resumptionToken') and
        (params_hash.keys - ignore).length > 1
      @errors << { code: 'badArgument',
                   description: 'resumptionToken is an exclusive argument.' }
    end

    # Check that all required args are present in the params hash.
    required.each do |arg|
      if params[arg].blank?
        # Make an exception for metadataPrefix, which is permitted to be
        # blank when resumptionToken is present.
        if arg == 'metadataPrefix' and
            params_hash.keys.include?('resumptionToken') and
            required.include?('metadataPrefix')
          # ok
        else
          @errors << { code: 'badArgument',
                       description: "Missing #{arg} argument." }
        end
      end
    end

    # Check that the params hash contains only allowed keys.
    (params_hash.keys - ignore).each do |key|
      unless allowed.include?(key)
        @errors << { code: 'badArgument',
                     description: "Illegal argument: #{key}" }
      end
    end
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

    # Verb-specific argument validation
    required_args = allowed_args = nil
    case params[:verb]
      when 'GetRecord' # 4.1
        required_args = allowed_args = %w(identifier metadataPrefix)
      when 'Identify' # 4.2
        allowed_args = required_args = %w()
      when 'ListIdentifiers' # 4.3
        allowed_args = %w(from metadataPrefix resumptionToken set until)
        required_args = %w(metadataPrefix)
      when 'ListMetadataFormats' # 4.4
        allowed_args = %w(identifier)
        required_args = %w()
      when 'ListRecords' # 4.5
        allowed_args = %w(from metadataPrefix set resumptionToken until)
        required_args = %w(metadataPrefix)
      when 'ListSets' # 4.6
        allowed_args = %w(resumptionToken)
        required_args = %w()
    end
    if required_args and allowed_args
      validate_arguments(required_args, allowed_args)
    end

    # metadataPrefix validation
    if params[:metadataPrefix].present? and
        !SUPPORTED_METADATA_FORMATS.map{ |f| f[:name] }.include?(params[:metadataPrefix])
      @errors << { code: 'cannotDisseminateFormat',
                   description: 'The metadata format identified by the '\
                     'metadataPrefix argument is not supported by this '\
                     'repository.' }
    end
  end

end
