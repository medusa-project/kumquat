# This file is a slightly modified copy of:
# https://github.com/medusa-project/dls-cantaloupe-docker/blob/master/image_files/delegates.rb

require 'json'

java_import java.net.HttpURLConnection
java_import java.net.URL
java_import java.io.BufferedReader
java_import java.io.FileNotFoundException
java_import java.io.InputStreamReader
java_import java.util.Base64
java_import java.util.stream.Collectors

class CustomDelegate

  attr_accessor :context

  def authorize(options = {})
    true
  end

  def extra_iiif2_information_response_keys(options = {})
    {}
  end

  ##
  # Identifiers that start with "v/" indicate video stills to be served from
  # UI MediaSpace (https://mediaspace.illinois.edu). All others are served from
  # S3.
  #
  def source(options = {})
    context['identifier'].start_with?('v/') ? 'HttpSource' : 'S3Source'
  end

  def azurestoragesource_blob_key(options = {})
  end

  def filesystemsource_pathname(options = {})
  end

  ##
  # Used for serving video still images from UI MediaSpace
  # (https://mediaspace.illinois.edu). Identifiers must have the following
  # format:
  #
  # v/:id/:id/:id
  #
  def httpsource_resource_info(options = {})
    identifier = context['identifier']
    parts = identifier.split('/')
    if parts.length == 4
      # We don't know the full dimensions, so we choose a reasonable width that
      # will allow us to get a decent quality thumbnail.
      # Since these are videos, we can assume that almost all will have a
      # 4:3 or 16:9 w:h ratio.
      width = 1000
      return sprintf('https://cdnsecakmi.kaltura.com/p/%s/sp/%s/thumbnail'\
        '/entry_id/%s/version/100001/width/%d',
                     parts[1], parts[2], parts[3], width)
    end
    nil
  end

  def jdbcsource_database_identifier(options = {})
  end

  def jdbcsource_media_type(options = {})
  end

  def jdbcsource_lookup_sql(options = {})
  end

  ##
  # Used for serving images from Medusa. Looks up object keys based on their
  # Medusa file UUIDs.
  #
  def s3source_object_info(options = {})
    identifier = context['identifier']

    url = URL.new(ENV['MEDUSA_URL'] + '/uuids/' +
                      URI.escape(identifier) + '.json')

    conn, is, reader = nil
    begin
      conn = url.openConnection
      conn.setRequestMethod 'GET'
      conn.setReadTimeout 30 * 1000
      conn.setRequestProperty('Authorization', 'Basic ' + encoded_credential)
      conn.connect
      is = conn.getInputStream
      status = conn.getResponseCode

      if status == 200
        reader = BufferedReader.new(InputStreamReader.new(is))
        entity = reader.lines.collect(Collectors.joining("\n"))
        return {
            'bucket' => ENV['S3SOURCE_BUCKET_NAME'],
            'key' => JSON.parse(entity)['relative_pathname'].reverse.chomp('/').reverse
        }
      else
        raise IOError, "Unexpected response status: #{status}"
      end
    rescue FileNotFoundException
      return nil
    rescue => e
      Java::edu.illinois.library.cantaloupe.script.Logger.warn("#{e}")
    ensure
      reader&.close
      is&.close
      conn&.disconnect
    end
  end

  def encoded_credential
    Base64.getEncoder.encodeToString(
        (ENV['MEDUSA_USER'] + ':' + ENV['MEDUSA_SECRET']).bytes)
  end

  def overlay(options = {})
  end

  def redactions(options = {})
    []
  end

end
