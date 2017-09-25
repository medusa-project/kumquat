##
# Encapsulates an internet host whose name or IP address can be described by
# a pattern, which may be either an exact hostname or IP address, or a
# range of such.
#
# Hostnames may be exact or may start with wildcards:
#
# * host.example.org
# * *.example.org
#
# IPs may be exact or ranges, which can be in wildcard or CIDR format:
#
# * 10.3.5.2
# * 10.0.*-10.53.*
# * 10.6
# * 10.6.0.0/16
#
# Comments starting with COMMENT_CHARACTER are allowed to trail the pattern.
#
# This class depends on the netaddr gem.
#
class Host < ApplicationRecord

  COMMENT_CHARACTER = '#'

  validate :validate_pattern

  ##
  # @return [String, nil] Comment portion of the pattern (the part after
  #                       COMMENT_CHARACTER).
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
    (self.pattern&.strip[0] == COMMENT_CHARACTER)
  end

  ##
  # @param string [String] Hostname or IP address
  # @return [Boolean]
  #
  def pattern_matches?(string)
    p = self.uncommented_pattern
    if p == string
      return true
    elsif wildcard_ip_range?(p)
      parts = p.split('-')
      return within_wildcard_range?(string, parts[0], parts[1])
    elsif cidr_ip_range?(p)
      return within_cidr_range?(string, p)
    elsif p.end_with?('*')
      filtered_pattern = p.gsub('*', '')
      return true if string.start_with?(filtered_pattern)
    elsif p.start_with?('*')
      filtered_pattern = p.gsub('*', '').reverse.chomp('.').reverse
      return true if string.end_with?(filtered_pattern)
    end
    false
  end

  ##
  # @return [String, nil] Pattern excluding any comment.
  #
  def uncommented_pattern
    if self.pattern
      index = self.pattern.index(COMMENT_CHARACTER)
      if index
        return self.pattern[0..index - 1].strip
      end
    end
    self.pattern
  end

  private

  ##
  # @param string [String] String to test.
  # @return [Boolean] Whether the given string is a CIDR IP range.
  #
  def cidr_ip_range?(string)
    begin
      # Check for CIDR range.
      NetAddr::CIDR.create(string)
      true
    rescue
      false
    end
  end

  ##
  # @param string [String] String to test.
  # @return [Boolean] Whether the given string is an IP address.
  #
  def ip?(string)
    !(string =~ /\A[0-9.]/).nil?
  end

  ##
  # @param string [String] String to test.
  # @return [Boolean] Whether the given string is an IP range.
  #
  def ip_range?(string)
    cidr_ip_range?(string) or wildcard_ip_range?(string)
  end

  def validate_pattern
    if self.pattern.blank?
      errors.add(:pattern, 'cannot be empty')
    end

    up = uncommented_pattern.strip

    # Wildcards are not allowed solo.
    if up == '*'
      errors.add(:pattern, 'contains only a wildcard')
    end

    if ip?(up) or ip_range?(up)
      # Allow any number as well as a wildcard character and slash, checking
      # only the uncommented portion.
      unless up.match(/\A[0-9\-\/.*_]+\Z/i)
        errors.add(:pattern, 'is malformed')
      end

      # If the pattern contains a slash, assume it's in CIDR format and check
      # it.
      if up.include?('/')
        begin
          NetAddr::CIDR.create(up)
        rescue
          errors.add(:pattern, 'is an invalid CIDR range')
        end
      end

      # Check that each quad is in the range 0-255.
      if up.gsub(/\D/, '.').split('.').select{ |q| q.to_i > 255 }.any?
        errors.add(:pattern, 'is  malformed')
      end
    else
      # Allow any hostname as well as a wildcard character, checking only the
      # uncommented portion.
      unless up.match(/\A[a-zA-Z0-9\-.*]+\Z/i)
        errors.add(:pattern, 'is malformed')
      end

      # Wildcards are only allowed in the first position.
      if up.include?('*') and up.index('*') > 0
        errors.add(:pattern, 'contains a wildcard that is not the first character')
      end
    end
  end

  ##
  # @param string [String] String to test.
  # @return [Boolean] Whether the given string is a wildcard IP range.
  #
  def wildcard_ip_range?(string)
    parts = string.split('-')
    parts.select{ |p| ip?(p) }.length == 2
  end

  ##
  # @param ip [String] IP to test.
  # @param cidr_pattern [String] CIDR range to test against.
  # @return [Boolean]
  #
  def within_cidr_range?(ip, cidr_pattern)
    NetAddr::CIDR.create(cidr_pattern).contains?(ip)
  end

  ##
  # @param ip [String] Full IP address
  # @param start [String] Start of the range (wildcards allowed)
  # @param end_ [String] End of the range (wildcards allowed)
  # @return [Boolean]
  #
  def within_wildcard_range?(ip, start, end_)
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
