##
# Encapsulates a rightsstatement.org rights statement.
#
# @see http://rightsstatements.org/page/1.0/
#
class RightsStatement

  attr_accessor :image, :info_uri, :name, :uri

  ALL_STATEMENTS = [
      {
          uri: 'http://rightsstatements.org/vocab/InC/1.0/',
          name: 'In Copyright',
          image: 'rightsstatements.org/InC.dark-white-interior.svg',
          info_uri: 'http://rightsstatements.org/page/InC/1.0/'
      },
      {
          uri: 'http://rightsstatements.org/vocab/InC-OW-EU/1.0/',
          name: 'EU Orphan Work',
          image: 'rightsstatements.org/InC-OW-EU.dark-white-interior.svg',
          info_uri: 'http://rightsstatements.org/page/InC-OW-EU/1.0/'
      },
      {
          uri: 'http://rightsstatements.org/vocab/InC-EDU/1.0/',
          name: 'In Copyright - Educational Use Permitted',
          image: 'rightsstatements.org/InC-EDU.dark-white-interior.svg',
          info_uri: 'http://rightsstatements.org/page/InC-EDU/1.0/'
      },
      {
          uri: 'http://rightsstatements.org/vocab/InC-NC/1.0/',
          name: 'In Copyright - Non-Commercial Use Permitted',
          image: 'rightsstatements.org/InC-NC.dark-white-interior.svg',
          info_uri: 'http://rightsstatements.org/page/InC-NC/1.0/'
      },
      {
          uri: 'http://rightsstatements.org/vocab/InC-RUU/1.0/',
          name: 'In Copyright - Rights-Holder(s) Unlocatable or Unidentifiable',
          image: 'rightsstatements.org/InC-RUU.dark-white-interior.svg',
          info_uri: 'http://rightsstatements.org/page/InC-RUU/1.0/'
      },
      {
          uri: 'http://rightsstatements.org/vocab/NoC-CR/1.0/',
          name: 'No Copyright - Contractual Restrictions',
          image: 'rightsstatements.org/NoC-CR.dark-white-interior.svg',
          info_uri: 'http://rightsstatements.org/page/NoC-CR/1.0/'
      },
      {
          uri: 'http://rightsstatements.org/vocab/NoC-NC/1.0/',
          name: 'No Copyright - Non-Commercial Use Only',
          image: 'rightsstatements.org/NoC-CR.dark-white-interior.svg',
          info_uri: 'http://rightsstatements.org/page/NoC-NC/1.0/'
      },
      {
          uri: 'http://rightsstatements.org/vocab/NoC-OKLR/1.0/',
          name: 'No Copyright - Other Known Legal Restrictions',
          image: 'rightsstatements.org/NoC-OKLR.dark-white-interior.svg',
          info_uri: 'http://rightsstatements.org/page/NoC-OKLR/1.0/'
      },
      {
          uri: 'http://rightsstatements.org/vocab/NoC-US/1.0/',
          name: 'No Copyright - United States',
          image: 'rightsstatements.org/NoC-US.dark-white-interior.svg',
          info_uri: 'http://rightsstatements.org/page/NoC-US/1.0/'
      },
      {
          uri: 'http://rightsstatements.org/vocab/CNE/1.0/',
          name: 'Copyright Not Evaluated',
          image: 'rightsstatements.org/CNE.dark-white-interior.svg',
          info_uri: 'http://rightsstatements.org/page/CNE/1.0/'
      },
      {
          uri: 'http://rightsstatements.org/vocab/UND/1.0/',
          name: 'Copyright Undetermined',
          image: 'rightsstatements.org/UND.dark-white-interior.svg',
          info_uri: 'http://rightsstatements.org/page/UND/1.0/'
      },
      {
          uri: 'http://rightsstatements.org/vocab/NKC/1.0/',
          name: 'No Known Copyright',
          image: 'rightsstatements.org/NKC.dark-white-interior.svg',
          info_uri: 'http://rightsstatements.org/page/NKC/1.0/'
      }
  ]

  ##
  # @return [Array<RightsStatement>]
  #
  def self.all_statements
    statements = ALL_STATEMENTS.map do |struct|
      RightsStatement.for_uri(struct[:uri])
    end
    statements
  end

  ##
  # @param uri [String]
  # @return [RightsStatement]
  #
  def self.for_uri(uri)
    statement = nil
    struct = ALL_STATEMENTS.select{ |s| s[:uri] == uri }.first
    if struct
      statement = RightsStatement.new
      struct.each { |key, value| statement.send("#{key}=", value) }
    end
    statement
  end

end
