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
          case @metadata_format
            when 'oai_qdc'
              oai_pmh_qdc_elements_for(@item, xml)
            else
              oai_pmh_dc_elements_for(@item, xml)
          end
        end
      end
    end
  end

end
