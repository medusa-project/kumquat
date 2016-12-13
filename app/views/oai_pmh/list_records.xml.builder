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
      xml.tag!('error', { 'code' => error[:code] }, error[:description])
    end
  else
    # 4.5
    xml.tag!('ListRecords') do
      @results.each do |item|
        # This should ideally never hit, but just to be safe...
        next unless item.collection
        xml.tag!('record') do
          xml.tag!('header') do
            xml.tag!('identifier', oai_pmh_identifier_for(item, @host))
            xml.tag!('datestamp', item.updated_at.strftime('%Y-%m-%d'))
            xml.tag!('setSpec', item.collection.repository_id)
          end
          xml.tag!('metadata') do
            xml.tag!('oai_dc:dc', {
                'xmlns:oai_dc' => 'http://www.openarchives.org/OAI/2.0/oai_dc/',
                'xmlns:dc' => 'http://purl.org/dc/elements/1.1/',
                'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
                'xsi:schemaLocation' => 'http://www.openarchives.org/OAI/2.0/oai_dc/ '\
              'http://www.openarchives.org/OAI/2.0/oai_dc.xsd'
            }) do
              oai_pmh_elements_for(item, xml)
            end
          end
        end
      end
      xml.tag!('resumptionToken',
               { 'completeListSize' => @total_num_results,
                 'cursor' => @results_offset,
                 'expirationDate' => @expiration_date },
               @next_page_available ? @resumption_token : nil)
    end
  end

end
