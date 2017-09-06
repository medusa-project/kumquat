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
  xml.tag!('request', @query, oai_pmh_url)

  # 3.2 #4, 3.6
  if @errors.any?
    @errors.each do |error|
      xml.tag!('error', { 'code' => error[:code] }, error[:description])
    end
  else
    # 4.2
    xml.tag!('Identify') do
      xml.tag!('repositoryName',
               Option::string(Option::Keys::WEBSITE_NAME))
      xml.tag!('baseURL', root_url)
      xml.tag!('protocolVersion', '2.0')
      xml.tag!('adminEmail', Option::string(Option::Keys::ADMINISTRATOR_EMAIL))
      xml.tag!('earliestDatestamp', @earliest_datestamp)
      xml.tag!('deletedRecord', 'no')
      xml.tag!('granularity', 'YYYY-MM-DDThh:mm:ssZ')
    end
  end

end
