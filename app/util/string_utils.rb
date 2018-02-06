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

  def self.rot18(str)
    str.tr('A-Ma-m0-4N-Zn-z5-9', 'N-Zn-z5-9A-Ma-m0-4')
  end

end