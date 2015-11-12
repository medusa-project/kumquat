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
    # 4.6
    xml.tag!('ListSets') do
      @collections.each do |collection|
        xml.tag!('set') do
          xml.tag!('setSpec', collection.key)
          xml.tag!('setName', collection.title)
          if collection.description
            xml.tag!('setDescription') do
              xml.tag!('oai_dc:dc', {
                  'xmlns:oai_dc' => 'http://www.openarchives.org/OAI/2.0/oai_dc/',
                  'xmlns:dc' => 'http://purl.org/dc/elements/1.1/',
                  'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
                  'xsi:schemaLocation' => 'xsi:schemaLocation="http://www.openarchives.org/OAI/2.0/oai_dc/ '\
                  'http://www.openarchives.org/OAI/2.0/oai_dc.xsd'
              }) do
                xml.tag!('dc:description', collection.description)
              end
            end
          end
        end
      end
    end
  end

end
