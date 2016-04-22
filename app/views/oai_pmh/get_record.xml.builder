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
    xml.tag!('GetRecord') do
      xml.tag!('record') do
        xml.tag!('header') do
          xml.tag!('identifier', @identifier)
          xml.tag!('datestamp', @item.updated_at.strftime('%Y-%m-%d'))
          xml.tag!('setSpec', @item.collection.repository_id)
        end
        xml.tag!('metadata') do
          xml.tag!('oai_dc:dc', {
              'xmlns:oai_dc' => 'http://www.openarchives.org/OAI/2.0/oai_dc/',
              'xmlns:dc' => 'http://purl.org/dc/elements/1.1/',
              'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
              'xsi:schemaLocation' => 'xsi:schemaLocation="http://www.openarchives.org/OAI/2.0/oai_dc/ '\
              'http://www.openarchives.org/OAI/2.0/oai_dc.xsd'
          }) do
            @item.elements.each do |element|
              # oai_dc supports only unqualified DC.
              dc_element = @item.collection.metadata_profile.element_defs.
                  where(name: element.name).first&.dc_map
              if dc_element and element.value.present?
                xml.tag!("dc:#{dc_element}", element.value)
              end
            end
          end
        end
      end
    end
  end

end
