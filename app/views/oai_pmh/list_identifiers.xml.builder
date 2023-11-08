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
    # 4.3
    xml.tag!('ListIdentifiers') do
      @results.each do |item|
        xml.tag!('header') do
          xml.tag!('identifier', oai_pmh_identifier_for(item, @host))
          xml.tag!('datestamp', item.updated_at.strftime('%Y-%m-%d'))
          xml.tag!('setSpec', item.collection.repository_id)
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
