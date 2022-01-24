# Eliminate whitespace
xml = Builder::XmlMarkup.new

xml.instruct!

xml.tag!('OAI-PMH', {
  'xmlns'              => 'http://www.openarchives.org/OAI/2.0/',
  'xmlns:xsi'          => 'http://www.w3.org/2001/XMLSchema-instance',
  'xsi:schemaLocation' => 'http://www.openarchives.org/OAI/2.0/ '\
                          'http://www.openarchives.org/OAI/2.0/OAI-PMH.xsd' }) do
  # 3.2 #3
  xml.tag!('responseDate', Time.now.utc.iso8601)

  # 3.2 #3
  xml.tag!('request', {}, oai_pmh_url)

  # 3.2 #4, 3.6
  xml.tag!('error', { 'code' => 500 }, @error.message)

  # Not a standard OAI-PMH element; assists in debugging in development only
  if Rails.env.development?
    xml.tag!('backtrace') do
      @error.backtrace.each do |frame|
        xml.tag!('frame', frame)
      end
    end
  end

end
