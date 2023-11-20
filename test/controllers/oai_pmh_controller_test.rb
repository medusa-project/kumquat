require 'test_helper'

##
# Tests are roughly in order and labeled by section according to:
#
# http://www.openarchives.org/OAI/openarchivesprotocol.html
#
class OaiPmhControllerTest < ActionDispatch::IntegrationTest

  setup do
    setup_elasticsearch
    @valid_identifier = 'oai:www.example.com:' +
        items(:compound_object_1001).repository_id
  end

  # 2.5.1
  test 'repository should not support deleted records' do
    get '/oai-pmh', params: { verb: 'Identify' }
    assert_select 'Identify > deletedRecord', 'no'
  end

  # 3.1.1
  test 'verb argument is required' do
    get '/oai-pmh'
    assert_select 'error', 'Missing verb argument.'
  end

  test 'verb argument must be legal' do
    get '/oai-pmh', params: { verb: 'cats' }
    assert_select 'error', 'Illegal verb argument.'
  end

  # 3.1.1.2
  test 'POST requests with an incorrect content type cause an error' do
    post '/oai-pmh', params: { verb: 'Identify' },
         headers: { 'Content-Type': 'text/plain' }
    assert_select 'error', 'Content-Type of POST requests must be '\
    '"application/x-www-form-urlencoded"'
  end

  # 3.1.1.2
  test 'POST requests with the correct content type work' do
    post '/oai-pmh', params: { verb: 'Identify' },
         headers: { 'Content-Type': 'application/x-www-form-urlencoded' }
    assert_select 'Identify > deletedRecord', 'no'
  end

  # 3.1.2.1
  test 'response content type must be text/xml' do
    get '/oai-pmh', params: { verb: 'Identify' }
    assert response.headers['Content-Type'].start_with?('text/xml')
  end

  # 3.2
  test 'response content type must be UTF-8' do
    get '/oai-pmh', params: { verb: 'Identify' }
    assert response.headers['Content-Type'].downcase.include?('charset=utf-8')
  end

  # 3.2
  test 'Error responses must validate against the OAI-PMH XML schema' do
    assert xsd_validate({})
  end

  test 'GetRecord responses must validate against the OAI-PMH XML schema' do
    assert xsd_validate({ verb: 'GetRecord', metadataPrefix: 'oai_dc' })
  end

  test 'Identify responses must validate against the OAI-PMH XML schema' do
    get '/oai-pmh', params: { verb: 'Identify' }
    assert xsd_validate({ verb: 'Identify' })
  end

  test 'ListIdentifiers responses must validate against the OAI-PMH XML schema' do
    assert xsd_validate({ verb: 'ListIdentifiers', metadataPrefix: 'oai_dc' })
  end

  test 'ListMetadataFormats responses must validate against the OAI-PMH XML schema' do
    assert xsd_validate({ verb: 'ListMetadataFormats', metadataPrefix: 'oai_dc' })
  end

  test 'ListRecords responses must validate against the OAI-PMH XML schema' do
    # TODO: this needs to be validated against multiple schemas
    #assert xsd_validate({ verb: 'ListRecords', metadataPrefix: 'oai_dc' })
  end

  test 'ListSets responses must validate against the OAI-PMH XML schema' do
    assert xsd_validate({ verb: 'ListSets', metadataPrefix: 'oai_dc' })
  end

  # 3.3.1
  test 'Identify response should include the correct date granularity' do
    get '/oai-pmh', params: { verb: 'Identify' }
    assert_select 'Identify > granularity', 'YYYY-MM-DDThh:mm:ssZ'
  end

  # 4.1 GetRecord
  test 'GetRecord returns a record when only correct arguments are passed' do
    get '/oai-pmh', params: { verb: 'GetRecord', metadataPrefix: 'oai_dc',
        identifier: @valid_identifier }
    assert_select 'GetRecord > record > header > identifier', @valid_identifier
  end

  test 'GetRecord returns errors when required arguments are missing' do
    get '/oai-pmh', params: { verb: 'GetRecord' }
    assert_select 'error', 'Missing identifier argument.'
    assert_select 'error', 'Missing metadataPrefix argument.'
  end

  test 'GetRecord returns errors when illegal arguments are provided' do
    get '/oai-pmh', params: { verb: 'GetRecord', cats: 'cats', dogs: 'dogs' }
    assert_select 'error', 'Illegal argument: cats'
    assert_select 'error', 'Illegal argument: dogs'
  end

  test 'GetRecord returns errors when arguments are invalid' do
    get '/oai-pmh', params: { verb: 'GetRecord',
                              identifier: @valid_identifier,
                              metadataPrefix: 'cats' }
    assert_select 'error', 'The metadata format identified by the '\
    'metadataPrefix argument is not supported by this repository.'

    get '/oai-pmh', params: { verb: 'GetRecord',
                              metadataPrefix: 'oai_dc',
                              identifier: 'cats' }
    assert_select 'error', 'The value of the identifier argument is unknown '\
    'or illegal in this repository.'
  end

  test 'GetRecord supports only oai_dc and oai_dcterms for the generic endpoint' do
    get '/oai-pmh', params: { verb: 'GetRecord',
                              identifier: @valid_identifier,
                              metadataPrefix: 'oai_dc' }
    assert_select 'GetRecord > record > header > identifier', @valid_identifier

    get '/oai-pmh', params: { verb: 'GetRecord',
                              identifier: @valid_identifier,
                              metadataPrefix: 'oai_dcterms' }
    assert_select 'GetRecord > record > header > identifier', @valid_identifier

    get '/oai-pmh', params: { verb: 'GetRecord',
                              identifier: @valid_identifier,
                              metadataPrefix: 'oai_primo' }
    assert_select 'error', 'The metadata format identified by the '\
    'metadataPrefix argument is not supported by this repository.'
  end

  test 'GetRecord supports only oai_dc and oai_idhh for the IDHH endpoint' do
    get '/oai-pmh/idhh', params: { verb: 'GetRecord',
                                   identifier: @valid_identifier,
                                   metadataPrefix: 'oai_dc' }
    assert_select 'GetRecord > record > header > identifier', @valid_identifier

    get '/oai-pmh/idhh', params: { verb: 'GetRecord',
                                   identifier: @valid_identifier,
                                   metadataPrefix: 'oai_idhh' }
    assert_select 'GetRecord > record > header > identifier', @valid_identifier

    get '/oai-pmh/idhh', params: { verb: 'GetRecord',
                                   identifier: @valid_identifier,
                                   metadataPrefix: 'oai_dcterms' }
    assert_select 'error', 'The metadata format identified by the '\
    'metadataPrefix argument is not supported by this repository.'
  end

  test 'GetRecord supports only oai_dc and oai_primo for the Primo endpoint' do
    get '/oai-pmh/primo', params: { verb: 'GetRecord',
                                    identifier: @valid_identifier,
                                    metadataPrefix: 'oai_dc' }
    assert_select 'GetRecord > record > header > identifier', @valid_identifier

    get '/oai-pmh/primo', params: { verb: 'GetRecord',
                                    identifier: @valid_identifier,
                                    metadataPrefix: 'oai_primo' }
    assert_select 'GetRecord > record > header > identifier', @valid_identifier

    get '/oai-pmh/primo', params: { verb: 'GetRecord',
                                    identifier: @valid_identifier,
                                    metadataPrefix: 'oai_idhh' }
    assert_select 'error', 'The metadata format identified by the '\
        'metadataPrefix argument is not supported by this repository.'
  end

  # 4.2 Identify
  test 'Identify returns correct information' do
    get '/oai-pmh', params: { verb: 'Identify' }
    assert_select 'Identify > repositoryName',
                  Setting::string(Setting::Keys::WEBSITE_NAME)
    assert_select 'Identify > baseURL', 'http://www.example.com/oai-pmh'
    assert_select 'Identify > protocolVersion', '2.0'
    items = Item.where(published: true).order(created_at: :desc).limit(1)
    assert_select 'Identify > earliestDatestamp', items.first.created_at.utc.iso8601
    assert_select 'Identify > deletedRecord', 'no'
    assert_select 'Identify > granularity', 'YYYY-MM-DDThh:mm:ssZ'
    assert_select 'Identify > adminEmail',
                  Setting::string(Setting::Keys::ADMINISTRATOR_EMAIL)
  end

  test 'Identify returns errors when illegal arguments are provided' do
    get '/oai-pmh', params: { verb: 'Identify', cats: 'cats', dogs: 'dogs' }
    assert_select 'error', 'Illegal argument: cats'
    assert_select 'error', 'Illegal argument: dogs'
  end

  # 4.3 ListIdentifiers
  test 'ListIdentifiers returns a list when correct arguments are passed and
  results are available' do
    get '/oai-pmh', params: { verb: 'ListIdentifiers',
                              metadataPrefix: 'oai_dc' }
    assert_select 'ListIdentifiers > header > identifier',
                  @valid_identifier

    get '/oai-pmh', params: { verb: 'ListIdentifiers',
                              metadataPrefix: 'oai_dc',
                              from: '2012-01-01',
                              until: '2030-01-01' }
    assert_select 'ListIdentifiers > header > identifier',
                  @valid_identifier
  end

  test 'ListIdentifiers returns an error when correct arguments are passed and
  no results are available' do
    get '/oai-pmh', params: { verb: 'ListIdentifiers',
                              metadataPrefix: 'oai_dc',
                              from: '1985-01-01',
                              until: '1985-01-02' }
    assert_select 'error', 'No matching records.'
  end

  test 'ListIdentifiers returns errors when certain arguments are missing' do
    get '/oai-pmh', params: { verb: 'ListIdentifiers' }
    assert_select 'error', 'Missing metadataPrefix argument.'
  end

  test 'ListIdentifiers returns errors when illegal arguments are provided' do
    get '/oai-pmh', params: { verb: 'ListIdentifiers', cats: 'cats', dogs: 'dogs' }
    assert_select 'error', 'Illegal argument: cats'
    assert_select 'error', 'Illegal argument: dogs'
  end

  test 'ListIdentifiers returns errors when arguments are invalid' do
    get '/oai-pmh', params: { verb: 'ListIdentifiers', metadataPrefix: 'cats' }
    assert_select 'error', 'The metadata format identified by the '\
    'metadataPrefix argument is not supported by this repository.'
  end

  test 'ListIdentifiers disallows all other arguments when resumptionToken is present' do
    get '/oai-pmh', params: { verb: 'ListIdentifiers',
                              resumptionToken: 'offset:10',
                              set: collections(:compound_object).repository_id }
    assert_select 'error', 'resumptionToken is an exclusive argument.'
  end

  # 4.4 ListMetadataFormats
  test 'ListMetadataFormats returns a list when no arguments are provided to
  the generic endpoint' do
    get '/oai-pmh', params: { verb: 'ListMetadataFormats' }
    assert_select 'ListMetadataFormats > metadataFormat > metadataPrefix',
                  'oai_dc'
    assert_select 'ListMetadataFormats > metadataFormat > metadataPrefix',
                  'oai_dcterms'
  end

  test 'ListMetadataFormats returns a list when no arguments are provided to
  the IDHH endpoint' do
    get '/oai-pmh/idhh', params: { verb: 'ListMetadataFormats' }
    assert_select 'ListMetadataFormats > metadataFormat > metadataPrefix',
                  'oai_dc'
    assert_select 'ListMetadataFormats > metadataFormat > metadataPrefix',
                  'oai_idhh'
  end

  test 'ListMetadataFormats returns a list when no arguments are provided to
  the Primo endpoint' do
    get '/oai-pmh/primo', params: { verb: 'ListMetadataFormats' }
    assert_select 'ListMetadataFormats > metadataFormat > metadataPrefix',
                  'oai_dc'
    assert_select 'ListMetadataFormats > metadataFormat > metadataPrefix',
                  'oai_primo'
  end

  test 'ListMetadataFormats accepts an optional identifier argument' do
    get '/oai-pmh', params: { verb: 'ListMetadataFormats',
                              identifier: @valid_identifier }
    assert_select 'ListMetadataFormats > metadataFormat > metadataPrefix',
                  'oai_dc'
  end

  test 'ListMetadataFormats returns an error when there are no metadata
  formats available for a given item' do
    pass # This should never happen, as all items will support oai_dc.
  end

  test 'ListMetadataFormats returns errors when illegal arguments are
  provided' do
    get '/oai-pmh', params: { verb: 'ListMetadataFormats', cats: 'cats',
                              dogs: 'dogs' }
    assert_select 'error', 'Illegal argument: cats'
    assert_select 'error', 'Illegal argument: dogs'
  end

  test 'ListMetadataFormats returns errors when arguments are invalid' do
    get '/oai-pmh', params: { verb: 'ListMetadataFormats', identifier: 'bogus' }
    assert_select 'error', 'The value of the identifier argument is unknown '\
    'or illegal in this repository.'
  end

  # 4.5 ListRecords
  test 'ListRecords returns a list when correct arguments are passed and
  results are available' do
    get '/oai-pmh', params: { verb: 'ListRecords', metadataPrefix: 'oai_dc' }
    assert_select 'ListRecords > record > header > identifier',
                  @valid_identifier

    get '/oai-pmh', params: { verb: 'ListRecords',
                              metadataPrefix: 'oai_dc',
                              from: '2012-01-01',
                              until: '2030-01-01' }
    assert_select 'ListRecords > record > header > identifier',
                  @valid_identifier
  end

  test 'ListRecords returns an error when correct arguments are passed and no
  results are available' do
    get '/oai-pmh', params: { verb: 'ListRecords', metadataPrefix: 'oai_dc',
        from: '1985-01-01', until: '1985-01-02' }
    assert_select 'error', 'No matching records.'
  end

  test 'ListRecords returns errors when certain arguments are missing' do
    get '/oai-pmh', params: { verb: 'ListRecords' }
    assert_select 'error', 'Missing metadataPrefix argument.'
  end

  test 'ListRecords returns errors when illegal arguments are provided' do
    get '/oai-pmh', params: { verb: 'ListRecords', cats: 'cats', dogs: 'dogs' }
    assert_select 'error', 'Illegal argument: cats'
    assert_select 'error', 'Illegal argument: dogs'
  end

  test 'ListRecords returns errors when arguments are invalid' do
    get '/oai-pmh', params: { verb: 'ListRecords', metadataPrefix: 'cats' }
    assert_select 'error', 'The metadata format identified by the '\
    'metadataPrefix argument is not supported by this repository.'
  end

  test 'ListRecords disallows all other arguments when resumptionToken is present' do
    get '/oai-pmh', params: { verb: 'ListRecords',
                              resumptionToken: 'offset:10',
                              set: collections(:compound_object).repository_id }
    assert_select 'error', 'resumptionToken is an exclusive argument.'
  end

  test 'ListRecords supports only oai_dc and oai_dcterms for the generic endpoint' do
    get '/oai-pmh', params: { verb: 'ListRecords', metadataPrefix: 'oai_dc' }
    assert_select 'ListRecords > record > header > identifier',
                  @valid_identifier

    get '/oai-pmh', params: { verb: 'ListRecords', metadataPrefix: 'oai_dcterms' }
    assert_select 'ListRecords > record > header > identifier',
                  @valid_identifier

    get '/oai-pmh', params: { verb: 'ListRecords', metadataPrefix: 'oai_idhh' }
    assert_select 'error', 'The metadata format identified by the '\
    'metadataPrefix argument is not supported by this repository.'
  end

  test 'ListRecords supports only oai_dc and oai_idhh for the IDHH endpoint' do
    get '/oai-pmh/idhh', params: { verb: 'ListRecords', metadataPrefix: 'oai_dc' }
    assert_select 'ListRecords > record > header > identifier',
                  @valid_identifier

    get '/oai-pmh/idhh', params: { verb: 'ListRecords', metadataPrefix: 'oai_idhh' }
    assert_select 'ListRecords > record > header > identifier',
                  @valid_identifier

    get '/oai-pmh/idhh', params: { verb: 'ListRecords', metadataPrefix: 'oai_dcterms' }
    assert_select 'error', 'The metadata format identified by the '\
    'metadataPrefix argument is not supported by this repository.'
  end

  test 'ListRecords supports only oai_dc and oai_primo for the Primo endpoint' do
    get '/oai-pmh/primo', params: { verb: 'ListRecords', metadataPrefix: 'oai_dc' }
    assert_select 'ListRecords > record > header > identifier',
                  @valid_identifier

    get '/oai-pmh/primo', params: { verb: 'ListRecords', metadataPrefix: 'oai_primo' }
    assert_select 'ListRecords > record > header > identifier',
                  @valid_identifier

    get '/oai-pmh/primo', params: { verb: 'ListRecords', metadataPrefix: 'oai_dcterms' }
    assert_select 'error', 'The metadata format identified by the '\
    'metadataPrefix argument is not supported by this repository.'
  end

  # 4.6 ListSets
  test 'ListSets returns a list when correct arguments are passed and results
  are available' do
    get '/oai-pmh', params: { verb: 'ListSets' }
    assert_select 'ListSets > set > setSpec', collections(:compound_object).repository_id
  end

  test 'ListSets returns errors when illegal arguments are provided' do
    get '/oai-pmh', params: { verb: 'ListSets', cats: 'cats', dogs: 'dogs' }
    assert_select 'error', 'Illegal argument: cats'
    assert_select 'error', 'Illegal argument: dogs'
  end

  test 'ListSets disallows all other arguments when resumptionToken is present' do
    get '/oai-pmh', params: { verb: 'ListSets',
                              resumptionToken: 'offset:10',
                              set: collections(:compound_object).repository_id }
    assert_select 'error', 'resumptionToken is an exclusive argument.'
  end

  private

  def xsd_validate(params_)
    get '/oai-pmh', params: params_
    doc = Nokogiri::XML(response.body)
    xsd = Nokogiri::XML::Schema(File.read(File.join(__dir__, 'OAI-PMH.xsd')))
    result = xsd.validate(doc)
    puts result if result.any?
    result.empty?
  end

end
