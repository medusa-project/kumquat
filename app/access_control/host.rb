##
# Encapsulates an internet host whose name or IP address can be covered by
# a pattern.
#
class Host < ActiveRecord::Base

  # Allow any hostname, IPv4 or IPv6 address, as well as a wildcard character.
  validates_format_of :pattern, with: /\A[a-zA-Z0-9\-.*_:]+\Z/i,
                      message: 'Pattern is invalid',
                      allow_blank: false

  ##
  # @param string [String] Hostname or IP address
  # @return [Boolean]
  #
  def pattern_matches?(string)
    if self.pattern == string
      return true
    elsif self.pattern.end_with?('*')
      filtered_pattern = self.pattern.gsub('*', '')
      return true if string.start_with?(filtered_pattern)
    elsif self.pattern.start_with?('*')
      filtered_pattern = self.pattern.gsub('*', '').reverse.chomp('.').reverse
      return true if string.end_with?(filtered_pattern)
    end
    false
  end

end
