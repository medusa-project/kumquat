class SpaceUtil

  ##
  # Parses a coordinate string such as:
  #
  # W 90⁰26'05"/ N 40⁰39'51"
  #
  # @param lat_long [String] Coordinate string.
  # @return [Hash,nil] Two-element hash with `latitude` and `longitude` keys
  #                    pointing to floats in decimal degrees; or nil if the
  #                    given string cannot be parsed.
  #
  def self.string_coordinates_to_coordinates(lat_long)
    coords = nil
    if lat_long
      parts = lat_long.split('/')
      if parts.length == 2
        coords = {}
        parts.each do |coordinate|
          # Try to parse the coordinate into a three-element array of floats.
          numerics = coordinate.gsub(/[^0-9]/, ' ').strip.split(' ').map(&:to_f)
          if numerics.length == 3
            # Convert to decimal degrees.
            decimal = numerics[0] + numerics[1] / 60.0 + numerics[2] / 3600.0
            if coordinate.include?('N')
              coords[:latitude] = decimal
            elsif coordinate.include?('S')
              coords[:latitude] = 0 - decimal
            elsif coordinate.include?('E')
              coords[:longitude] = decimal
            elsif coordinate.include?('W')
              coords[:longitude] = 0 - decimal
            end
          end
        end
      end
      if coords and (coords.length != 2 or coords[:latitude].blank? or
            coords[:longitude].blank?)
        coords = nil
      end
    end
    coords
  end

end