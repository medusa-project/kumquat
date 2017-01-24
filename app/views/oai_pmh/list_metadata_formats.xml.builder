# Eliminate whitespace
xml = Builder::XmlMarkup.new

xml.instruct!

xml.tag!('OAI-PMH',
         { 'xmlns' => 'http://www.openarchives.org/OAI/2.0/',
           'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
           'xsi:schemaLocation' => 'http://www.openarchives.org/OAI/2.0/ '\
           'http://www.openarchives.org/OAI/2.0/OAI-PMH.xsd'
         }) do
  # 3.2 #3
  xml.tag!('responseDate', Time.now.utc.iso8601)

  # 3.2 #3
  query = @errors.select{ |e| %w(badVerb badArgument).include?(e[:code]) }.any? ?
      {} : params.except('controller', 'action')
  xml.tag!('request', query, oai_pmh_url)

  # 3.2 #4, 3.6
  if @errors.any?
    @errors.each do |error|
      xml.tag!('error', { 'code': error[:code] }, error[:description])
    end
  else
    # 4.4
    xml.tag!('ListMetadataFormats') do
      xml.tag!('metadataFormat') do
        xml.tag!('metadataPrefix', 'oai_dc')
        xml.tag!('schema', 'http://www.openarchives.org/OAI/2.0/oai_dc.xsd')
        xml.tag!('metadataNamespace',
                 'http://www.openarchives.org/OAI/2.0/oai_dc/')
      end
      xml.tag!('metadataFormat') do
        xml.tag!('metadataPrefix', 'oai_qdc')
        xml.tag!('schema',
                 'http://dublincore.org/schemas/xmls/qdc/2003/04/02/appqualifieddc.xsd')
        xml.tag!('metadataNamespace', 'http://oclc.org/appqualifieddc/')
      end
    end
  end

end
