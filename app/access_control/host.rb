##
# Encapsulates an internet host whose name or IP address can be covered by
# a pattern.
#
# Wildcards are allowed in both IPs and hostnames, as in:
# *.example.org
# 10.0.*
#
# IP ranges are also allowed, as in:
# 10.0.*-10.10.*
#
# Comments are allowed anywhere in the pattern, starting with
# COMMENT_CHARACTER.
#
class Host < ActiveRecord::Base

  COMMENT_CHARACTER = '#'

  # Allow any hostname or IPv4 address, as well as a wildcard character and a
  # pound sign for comments.
  validates_format_of :pattern, with: /\A[a-zA-Z0-9\-#.*_]+\Z/i,
                      message: 'Pattern is invalid',
                      allow_blank: false

  ##
  # @return [String] Comment portion of the pattern (the part after
  #                  COMMENT_CHARACTER).
  #
  def comment
    if self.pattern
      index = self.pattern.index(COMMENT_CHARACTER)
      if index
        return self.pattern[(index + 1)..self.pattern.length].strip
      end
    end
    nil
  end

  ##
  # @return [Boolean]
  #
  def commented_out?
    self.pattern ? (self.pattern.strip.index(COMMENT_CHARACTER) == 0) : true
  end

  ##
  # @param string [String] Any string
  # @return [Boolean]
  #
  def ip?(string)
    !(string =~ /\A[0-9.]/).nil?
  end

  ##
  # @return [Boolean]
  #
  def ip_range?(string)
    parts = string.split('-')
    parts.select{ |p| ip?(p) }.length == 2
  end

  ##
  # @param string [String] Hostname or IP address
  # @return [Boolean]
  #
  def pattern_matches?(string)
    if self.commented_out?
      return false
    elsif self.pattern == string
      return true
    elsif ip_range?(self.pattern)
      parts = self.pattern.split('-')
      return within_range?(string, parts[0], parts[1])
    elsif self.pattern.end_with?('*')
      filtered_pattern = self.pattern.gsub('*', '')
      return true if string.start_with?(filtered_pattern)
    elsif self.pattern.start_with?('*')
      filtered_pattern = self.pattern.gsub('*', '').reverse.chomp('.').reverse
      return true if string.end_with?(filtered_pattern)
    end
    false
  end

  ##
  # @param ip [String] Full IP address
  # @param start [String] Start of the range (wildcards allowed)
  # @param end_ [String] End of the range (wildcards allowed)
  # @return [Boolean]
  #
  def within_range?(ip, start, end_)
    return false if self.commented_out?

    ip_groups = ip.gsub('*', '').split('.')
    start_groups = start.gsub('*', '').split('.')
    end_groups = end_.gsub('*', '').split('.')

    4.times do |level|
      ip_group = ip_groups[level].to_i
      start_group = start_groups[level].to_i
      end_group = end_groups[level].to_i
      return false if (start_group > 0 and ip_group < start_group) or
          (end_group > 0 and ip_group > end_group)
    end
    true
  end

end
