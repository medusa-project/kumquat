class StringUtils

  UUID_REGEX = /\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/

  def self.base16(str)
    ret = ''
    str.each_char do |c|
      ch = c.ord.to_s(16)
      if ch.size == 1
        ch = '0' + ch
      end
      ret += ch
    end
    ret.downcase
  end

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
  # @param start_time [Time]
  # @param index [Integer]
  # @param count [Integer]
  # @param message [String]
  # @return [void]
  #
  def self.print_progress(start_time, index, count, message)
    str = "#{message}: #{StringUtils.progress(start_time, index, count)}"
    print "#{str.ljust(80)}\r"
  end

  ##
  # @param start_time [Time]
  # @param index [Integer]
  # @param count [Integer]
  # @return [String] Progress string containing percent complete and ETA.
  #
  def self.progress(start_time, index, count)
    pct = index / count.to_f
    eta = TimeUtil.eta(start_time, pct).localtime.strftime('%-m/%d %l:%M %p')
    "#{(pct * 100).round(2)}% [ETA: #{eta}]"
  end

  def self.rot18(str)
    str.tr('A-Ma-m0-4N-Zn-z5-9', 'N-Zn-z5-9A-Ma-m0-4')
  end

  ##
  # @param str [String] String to strip leading articles from.
  # @return [String] New string with leading articles stripped.
  #
  def self.strip_leading_articles(str)
    # See: http://access.rdatoolkit.org/rdaappc_rdac-26.html

    # English: a, an, d', de, the, ye
    # French:  l', la, le, les, un* (skipped), une* (skipped)
    str.gsub(/^(a |an |d'|d’|de |the |ye |l'|l’|la |le |les )/i, '')
  end

end
