##
# Helper class for converting times and durations.
#
class TimeUtil

  LOGGER = CustomLogger.new(TimeUtil)

  ##
  # Estimates completion time based on a progress percentage.
  #
  # @param start_time [Time]
  # @param percent [Float]
  # @return [Time]
  #
  def self.eta(start_time, percent)
    if percent == 0
      1.year.from_now
    else
      start = start_time.utc
      now = Time.now.utc
      Time.at(start + ((now - start) / percent))
    end
  end

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
  # @param seconds [Float]
  # @return [String] String in hh:mm:ss format.
  #
  def self.seconds_to_hms(seconds)
    if seconds.to_f == seconds
      seconds = seconds.to_f
      # hours
      hr = seconds / 60.0 / 60.0
      floor = hr.floor
      rem = hr - floor
      hr = floor
      # minutes
      min = rem * 60
      floor = min.floor
      rem = min - floor
      min = floor
      # seconds
      sec = rem * 60

      return sprintf('%s:%s:%s',
                     hr.round.to_s.rjust(2, '0'),
                     min.round.to_s.rjust(2, '0'),
                     sec.round.to_s.rjust(2, '0'))
    end
    raise ArgumentError, "#{seconds} is not in a supported format."
  end

  ##
  # Tries to create a Time instance from an arbitrary date string as might
  # appear in MARC, DC, or some other free-form metadata.
  #
  # @param date [String]
  # @return [Array<Time>] Array of 0-2 Time instances indicating either a
  #                       point date or a date range.
  #
  def self.parse_date(date)
    if date
      iso8601 = nil

      # YYYY:MM:DD HH:MM:SS
      if date.match(/[0-9]{4}:[0-1][0-9]:[0-3][0-9] [0-1][0-9]:[0-5][0-9]:[0-5][0-9]/)
        parts = date.split(' ')
        date_parts = parts.first.split(':')
        time_parts = parts.last.split(':')
        iso8601 = "#{date_parts[0]}-#{date_parts[1]}-#{date_parts[2]}T"\
          "#{time_parts[0]}:#{time_parts[1]}:#{time_parts[2]}"
      # ISO-8601 formats
      # Credit: http://www.pelagodesign.com/blog/2009/05/20/iso-8601-date-validation-that-doesnt-suck/
      elsif date.match(/^([\+-]?\d{4}(?!\d{2}\b))((-?)((0[1-9]|1[0-2])(\3([12]\d|0[1-9]|3[01]))?|W([0-4]\d|5[0-2])(-?[1-7])?|(00[1-9]|0[1-9]\d|[12]\d{2}|3([0-5]\d|6[1-6])))([T\s]((([01]\d|2[0-3])((:?)[0-5]\d)?|24\:?00)([\.,]\d+(?!:))?)?(\17[0-5]\d([\.,]\d+)?)?([zZ]|([\+-])([01]\d|2[0-3]):?([0-5]\d)?)?)?)?$/)
        iso8601 = date
        if iso8601.match(/^\d{4}-\d{2}$/)
          iso8601 += '-01'
        end
      end

      begin
        if iso8601 and iso8601.length > 4
          return [Time.parse(iso8601)]
        end
        return Marc::Dates::parse(date)
      rescue ArgumentError
        LOGGER.warn("TimeUtil.parse_date(): unable to parse \"#{date}\"")
      end
    end
    nil
  end

end