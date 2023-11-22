##
# A group of one or more network hosts described by hostname, IP address, or
# IP address range.
#
# Hostnames may be exact or may include wildcards:
#
# * `host.example.org`
# * `*.example.org`
# * `test.*.example.org`
#
# IPs may be exact or ranges, which can be in wildcard or CIDR format:
#
# * `10.3.5.2`
# * `10.0.*-10.53.*`
# * `10.6`
# * `10.6.0.0/16`
#
# Comments starting with {COMMENT_CHARACTER} are allowed to trail the pattern.
#
# This class depends on the netaddr gem.
#
class HostGroup < ApplicationRecord

  COMMENT = '#'

  has_and_belongs_to_many :allowing_collections, class_name: 'Collection',
                          foreign_key: :allowed_host_group_id
  has_and_belongs_to_many :denying_collections, class_name: 'Collection',
                          foreign_key: :denied_host_group_id
  has_and_belongs_to_many :allowing_items, class_name: 'Item',
                          foreign_key: :allowed_host_group_id
  has_and_belongs_to_many :denying_items, class_name: 'Item',
                          foreign_key: :denied_host_group_id

  validates :key, presence: true, length: { maximum: 30 },
            uniqueness: { case_sensitive: false }
  validates :name, presence: true, length: { maximum: 255 },
            uniqueness: { case_sensitive: false }

  validate :validate_pattern

  ##
  # @param hostname [String]   Full hostname.
  # @param ip_address [String] Full IP address.
  # @return [Set<Host>]
  #
  def self.all_matching_hostname_or_ip(hostname, ip_address)
    groups = Set.new
    HostGroup.all.each do |group|
      groups << group if group.pattern_matches?(hostname) or
          group.pattern_matches?(ip_address)
    end
    groups
  end

  ##
  # @return [String, nil] Comment portion of the pattern (the part after
  #                       {#COMMENT}).
  #
  def comment
    if self.pattern
      index = self.pattern.index(COMMENT)
      if index
        return self.pattern[(index + 1)..self.pattern.length].strip
      end
    end
    nil
  end

  ##
  # @param string [String] Hostname or IP address
  # @return [Boolean]
  #
  def pattern_matches?(string)
    lines = self.pattern.split("\n")
    match = false
    lines.each do |line|
      if line == string
        match = true
      elsif wildcard_ip_range?(line)
        parts = line.split('-')
        match = within_wildcard_range?(string, parts[0], parts[1])
      elsif cidr_ip_range?(line)
        match = within_cidr_range?(string, line)
      elsif line.include?('*')
        match = File.fnmatch(line, string)
      end
      break if match
    end
    match
  end

  def to_s
    "#{self.name}"
  end

  private

  ##
  # @param string [String] String to test.
  # @return [Boolean] Whether the given string is a CIDR IP range.
  #
  def cidr_ip_range?(string)
    begin
      # Check for CIDR range.
      NetAddr::IPv4Net.parse(string)
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
    valid_lines = 0
    self.pattern.split("\n").each do |line|
      comment_idx = line.index(COMMENT)
      if comment_idx and comment_idx > 0
        line = line[0..(comment_idx - 1)]
      elsif comment_idx == 0
        next
      end
      line.strip!

      next if line.blank?

      # Wildcards are not allowed solo.
      if line == '*'
        errors.add(:pattern, 'contains only a wildcard')
      end

      if ip?(line) or ip_range?(line)
        # Allow any number as well as a wildcard character and slash, checking
        # only the uncommented portion.
        unless line.match(/\A[0-9\-\/.*_]+\Z/i)
          errors.add(:pattern, 'is malformed')
        end

        # If the pattern contains a slash, assume it's in CIDR format.
        if line.include?('/')
          begin
            NetAddr::IPv4Net.parse(line)
          rescue
            errors.add(:pattern, 'is an invalid CIDR range')
          end
        end

        # Check that each quad is in the range 0-255.
        if line.gsub(/\D/, '.').split('.').find{ |q| q.to_i > 255 }
          errors.add(:pattern, 'is  malformed')
        end
      else
        # Allow any hostname as well as a wildcard character, checking only the
        # uncommented portion.
        unless line.match(/\A[a-zA-Z0-9\-.*]+\Z/i)
          errors.add(:pattern, 'is malformed')
        end

        # Wildcards are only allowed in the first position.
        if line.include?('*') and line.index('*') > 0
          errors.add(:pattern, 'contains a wildcard that is not the first character')
        end
      end
      valid_lines += 1
    end
    if valid_lines == 0
      errors.add(:pattern, 'has no valid lines')
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
    begin
      subnet = NetAddr::IPv4Net.parse(cidr_pattern)
      return subnet.contains(NetAddr::IPv4.parse(ip))
    rescue
      return false
    end
  end

  ##
  # @param ip [String] Full IP address
  # @param start [String] Start of the range (wildcards allowed)
  # @param end_ [String] End of the range (wildcards allowed)
  # @return [Boolean]
  #
  def within_wildcard_range?(ip, start, end_)
    ip_groups    = ip.gsub('*', '').split('.')
    start_groups = start.gsub('*', '').split('.')
    end_groups   = end_.gsub('*', '').split('.')

    4.times do |level|
      ip_group    = ip_groups[level].to_i
      start_group = start_groups[level].to_i
      end_group   = end_groups[level].to_i
      return false if (start_group > 0 and ip_group < start_group) or
          (end_group > 0 and ip_group > end_group)
    end
    true
  end

end
