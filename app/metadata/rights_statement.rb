##
# Encapsulates a rightsstatement.org rights statement.
#
# @see http://rightsstatements.org/page/1.0/
#
class RightsStatement

  attr_accessor :image, :name, :uri

  ALL_STATEMENTS = [
      {
          uri: 'http://rightsstatements.org/vocab/InC/1.0/',
          name: 'In Copyright',
          image: 'InC.white.svg'
      },
      {
          uri: 'http://rightsstatements.org/vocab/InC-OW-EU/1.0/',
          name: 'EU Orphan Work',
          image: 'InC-OW-EU.white.svg'
      },
      {
          uri: 'http://rightsstatements.org/vocab/InC-EDU/1.0/',
          name: 'In Copyright - Educational Use Permitted',
          image: 'InC-EDU.white.svg'
      },
      {
          uri: 'http://rightsstatements.org/vocab/InC-NC/1.0/',
          name: 'In Copyright - Non-Commercial Use Permitted',
          image: 'InC-NC.white.svg'
      },
      {
          uri: 'http://rightsstatements.org/vocab/InC-RUU/1.0/',
          name: 'In Copyright - Rights-Holder(s) Unlocatable or Unidentifiable',
          image: 'InC-RUU.white.svg'
      },
      {
          uri: 'http://rightsstatements.org/vocab/NoC-CR/1.0/',
          name: 'No Copyright - Contractual Restrictions',
          image: 'NoC-CR.white.svg'
      },
      {
          uri: 'http://rightsstatements.org/vocab/NoC-NC/1.0/',
          name: 'No Copyright - Non-Commercial Use Only',
          image: 'NoC-NC.white.svg'
      },
      {
          uri: 'http://rightsstatements.org/vocab/NoC-OKLR/1.0/',
          name: 'No Copyright - Other Known Legal Restrictions',
          image: 'NoC-OKLR.white.svg'
      },
      {
          uri: 'http://rightsstatements.org/vocab/NoC-US/1.0/',
          name: 'No Copyright - United States',
          image: 'NoC-US.white.svg'
      },
      {
          uri: 'http://rightsstatements.org/vocab/CNE/1.0/',
          name: 'Copyright Not Evaluated',
          image: 'CNE.white.svg'
      },
      {
          uri: 'http://rightsstatements.org/vocab/UND/1.0/',
          name: 'Copyright Undetermined',
          image: 'UND.white.svg'
      },
      {
          uri: 'http://rightsstatements.org/vocab/NKC/1.0/',
          name: 'No Known Copyright',
          image: 'NKC.white.svg'
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
