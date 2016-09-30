class TimeUtil

  ##
  # @param date [String]
  # @return [Time]
  #
  def self.string_date_to_time(date)
    iso8601 = nil
    # Tests should be in order of most to least complex.
    # YYYY:MM:DD HH:MM:SS
    if date.match('[0-9]{4}:[0-1][0-9]:[0-3][0-9] [0-1][0-9]:[0-5][0-9]:[0-5][0-9]')
      parts = date.split(' ')
      date_parts = parts.first.split(':')
      time_parts = parts.last.split(':')
      iso8601 = "#{date_parts[0]}-#{date_parts[1]}-#{date_parts[2]}T"\
      "#{time_parts[0]}:#{time_parts[1]}:#{time_parts[2]}Z"
      # YYYY-MM-DD
    elsif date.match('[0-9]{4}-[0-1][0-9]-[0-3][0-9]')
      iso8601 = "#{date}T00:00:00Z"
      # YYYY:MM:DD
    elsif date.match('[0-9]{4}:[0-1][0-9]:[0-3][0-9]')
      iso8601 = "#{date.gsub(':', '-')}T00:00:00Z"
      # YYYY (1000-)
    elsif date.match('[0-9]{4}')
      iso8601 = "#{date}-01-01T00:00:00Z"
    end
    if iso8601
      begin
        return Time.parse(iso8601)
      rescue ArgumentError
        Rails.logger.warn("TimeUtil.string_date_to_time: unable to parse \"#{iso8601}\"")
      end
    end
    nil
  end

end