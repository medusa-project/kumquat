module NaturalSort

  def <=>(other)
    if i_s_pattern.start_with?(other.i_s_pattern) or
        other.i_s_pattern.start_with?(i_s_pattern)
      ints_and_strings <=> other.ints_and_strings
    else
      scrubbed <=> other.scrubbed
    end
  end

  def scrubbed
    self.to_s.downcase.gsub(/\Athe |\Aa |\Aan /, "").lstrip.gsub(/\s+/, " ")
  end

  def ints_and_strings
    self.scrubbed.scan(/\d+|\D+/).map{|s| s =~ /\d/ ? s.to_i : s}
  end

  def i_s_pattern
    self.ints_and_strings.map{|el| el.is_a?(Integer) ? :i : :s}.join
  end

end
