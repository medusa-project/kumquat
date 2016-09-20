# Eliminate whitespace
xml = Builder::XmlMarkup.new

xml.instruct!

xml.tag!('dls:Error',
         { 'xmlns:dls' => 'http://digital.library.illinois.edu/terms#' }) do

  xml.tag!('dls:message', message)

end

