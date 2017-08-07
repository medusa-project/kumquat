class TimeUtil

  ##
  # @param hms [String] Duration in `hh:mm:ss.ms` format
  # @return [Float] Seconds.
  # @raises [ArgumentError]
  #
  def self.hms_to_seconds(hms)
    if hms
      parts = hms.split(':')
      if parts.length == 3
        return parts[0].to_i * 60 * 60 + parts[1].to_i * 60 + parts[2].to_f
      end
    end
    raise ArgumentError, "#{hms} is not in a supported format."
  end

  ##
  # Tries to create a Time instance from an arbitrary date string as would
  # appear in metadata.
  #
  # Supported string formats:
  #
  # * ISO-8601
  # * YYYY:MM:DD HH:MM:SS
  # * YYYY:MM:DD
  # * YYYY-MM-DD
  # * YYYY
  # * [YYYY]
  # * [YYYY?]
  #
  #
  # @param date [String]
  # @return [Time] Time instance in UTC.
  #
  def self.string_date_to_time(date)
    if date
      iso8601 = nil

      # YYYY:MM:DD HH:MM:SS
      if date.match('[0-9]{4}:[0-1][0-9]:[0-3][0-9] [0-1][0-9]:[0-5][0-9]:[0-5][0-9]')
        parts = date.split(' ')
        date_parts = parts.first.split(':')
        time_parts = parts.last.split(':')
        iso8601 = "#{date_parts[0]}-#{date_parts[1]}-#{date_parts[2]}T"\
          "#{time_parts[0]}:#{time_parts[1]}:#{time_parts[2]}Z"
      # YYYY:MM:DD
      elsif date.match('[0-9]{4}:[0-1][0-9]:[0-3][0-9]')
        iso8601 = "#{date.gsub(':', '-')}T00:00:00Z"
      # YYYY-MM-DD
      elsif date.match('[0-9]{4}-[0-1][0-9]-[0-3][0-9]')
        iso8601 = "#{date}T00:00:00Z"
      # YYYY
      elsif date.match(/^[0-9]{4}$/)
        iso8601 = "#{date}-01-01T00:00:00Z"
      # [YYYY]
      elsif date.match(/^\[[0-9]{4}\]$/)
        iso8601 = "#{date.gsub(/[^0-9]/, '')}-01-01T00:00:00Z"
      # [YYYY?]
      elsif date.match(/^\[[0-9]{4}\?\]$/)
        iso8601 = "#{date.gsub(/[^0-9]/, '')}-01-01T00:00:00Z"
      # ISO-8601 formats
      # See: http://www.pelagodesign.com/blog/2009/05/20/iso-8601-date-validation-that-doesnt-suck/
      elsif date.match(/^([\+-]?\d{4}(?!\d{2}\b))((-?)((0[1-9]|1[0-2])(\3([12]\d|0[1-9]|3[01]))?|W([0-4]\d|5[0-2])(-?[1-7])?|(00[1-9]|0[1-9]\d|[12]\d{2}|3([0-5]\d|6[1-6])))([T\s]((([01]\d|2[0-3])((:?)[0-5]\d)?|24\:?00)([\.,]\d+(?!:))?)?(\17[0-5]\d([\.,]\d+)?)?([zZ]|([\+-])([01]\d|2[0-3]):?([0-5]\d)?)?)?)?$/)
        iso8601 = date
      end

      if iso8601
        begin
          return Time.parse(iso8601).utc
        rescue ArgumentError
          CustomLogger.instance.
              warn("TimeUtil.string_date_to_time: unable to parse \"#{date}\"")
        end
      end
    end
    nil
  end

end