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
      xml.tag!('error', { 'code': error[:code] }, error[:description])
    end
  else
    # 4.4
    xml.tag!('ListMetadataFormats') do
      @metadata_formats.each do |format|
        xml.tag!('metadataFormat') do
          xml.tag!('metadataPrefix', format[:prefix])
          xml.tag!('schema', format[:schema])
          xml.tag!('metadataNamespace', format[:uri])
        end
      end
    end
  end

end
