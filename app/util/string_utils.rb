class StringUtils

  UUID_REGEX = /\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/

  ##
  # Left-pads all numbers in the given string with the given character to the
  # given length.
  #
  # @param str [String]
  # @param pad_char [String]
  # @param length [Integer]
  # @return [String]
  #
  def self.pad_numbers(str, pad_char, length)
    str.to_s.gsub(/\d+/) { |match| match.rjust(length, pad_char) }
  end

  def self.rot18(str)
    str.tr('A-Ma-m0-4N-Zn-z5-9', 'N-Zn-z5-9A-Ma-m0-4')
  end

end
