##
# Assortment of string-related utility methods.
#
class StringUtils

  EMAIL_REGEX  = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
  TRUE_STRINGS = %w(true True TRUE yes Yes YES 1)
  UUID_REGEX   = /\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/

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

  ##
  # Performs ROT-18 on a string. This is used to apparently "scramble" them in
  # an easily reversible way.
  #
  # @param str [String] String to encode.
  # @return [String]    Encoded string.
  #
  def self.rot18(str)
    str.tr('A-Ma-m0-4N-Zn-z5-9', 'N-Zn-z5-9A-Ma-m0-4')
  end

  ##
  # Strips leading articles from an English or French string.
  #
  # @param str [String] String to strip leading articles from.
  # @return [String]    New string with leading articles stripped.
  #
  def self.strip_leading_articles(str)
    # See: http://access.rdatoolkit.org/rdaappc_rdac-26.html
    # English: a, an, d', de, the, ye
    # French:  l', la, le, les, un* (skipped), une* (skipped)
    str.gsub(/^(a |an |d'|d’|de |the |ye |l'|l’|la |le |les )/i, '')
  end

  ##
  # Converts a string to a boolean based on its text.
  #
  # @param str [String]
  # @return [Boolean]
  #
  def self.to_b(str)
    TRUE_STRINGS.include?(str)
  end

end
