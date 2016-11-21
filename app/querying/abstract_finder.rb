class AbstractFinder

  def initialize
    @include_unpublished = false
    @start = 0
    @limit = 999999
    @loaded = false
  end

  ##
  # @param hostname [String]
  # @return [self]
  #
  def client_hostname(hostname)
    @client_hostname = hostname
    self
  end

  ##
  # @param string [String]
  # @return [self]
  #
  def client_ip(string)
    @client_ip = string
    self
  end

  ##
  # @param user [User]
  # @return [self]
  #
  def client_user(user)
    @client_user = user
    self
  end

  ##
  # @param queries [Array]
  # @return [self]
  #
  def filter_queries(queries)
    @filter_queries = queries
    self
  end

  ##
  # @param boolean [Boolean]
  # @return [self]
  def include_unpublished(boolean)
    @include_unpublished = boolean
    self
  end

  ##
  # @param limit [Integer]
  # @return [self]
  #
  def limit(limit)
    @limit = limit.to_i
    self
  end

  ##
  # @return [Integer]
  #
  def page
    (@start / @limit.to_f).ceil + 1 if @limit > 0 || 1
  end

  ##
  # @param string [String]
  # @return [self]
  #
  def query(string) # TODO: separate query() and query_field() methods
    if string.present?
      parts = string.split(':')
      value = "*#{parts.last.gsub(' ', '*')}*"
      if parts.length > 1
        @query = "#{parts.first}:#{value}"
      else
        @query = value
      end
    end
    self
  end

  ##
  # @param orders [String]
  # @return [self]
  #
  def sort(*orders)
    @sort = orders
    self
  end

  alias_method :order, :sort

  ##
  # @param start [Integer]
  # @return [self]
  #
  def start(start)
    @start = start.to_i
    self
  end

  ##
  # @return [Array<String>]
  #
  def suggestions
    suggestions = []
    if @loaded and @query.present? and count < 1
      suggestions = Solr.instance.suggestions(@query)
    end
    suggestions
  end

  protected

  ##
  # @return [Set<Role>] Set of Roles associated with the client user, if
  #                     available, and the client hostname/IP address.
  #
  def roles
    roles = Set.new
    roles += @client_user.roles if @client_user
    roles += Role.all_matching_hostname_or_ip(@client_hostname, @client_ip) if
        @client_hostname or @client_ip
    roles
  end

end