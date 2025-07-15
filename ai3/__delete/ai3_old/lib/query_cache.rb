# frozen_string_literal: true

# QueryCache: Manages caching of user queries and their responses
class QueryCache
  require 'lru_redux'
  require 'logger'

  def initialize(ttl: 3600, max_size: 100)
    @cache = LruRedux::TTL::Cache.new(max_size, ttl)
    @logger = Logger.new(STDOUT)
    @logger.level = Logger::INFO
    log_message(:info, "QueryCache initialized with TTL: #{ttl} seconds and max size: #{max_size}.")
  end

  # Add a query and its response to the cache
  def add(query, response)
    log_message(:info, "Adding query to cache: #{query}")
    @cache[query] = response
  rescue StandardError => e
    log_message(:error, "Failed to add query to cache: #{e.message}")
  end

  # Retrieve a cached response for a given query
  def retrieve(query)
    response = @cache[query]
    if response
      log_message(:info, "Cache hit for query: #{query}")
      response
    else
      log_message(:info, "Cache miss for query: #{query}")
      nil
    end
  rescue StandardError => e
    log_message(:error, "Failed to retrieve query from cache: #{e.message}")
    nil
  end

  private

  # Log messages with different severity levels
  def log_message(severity, message)
    case severity
    when :info
      @logger.info(message)
    when :warn
      @logger.warn(message)
    when :error
      @logger.error(message)
    else
      @logger.debug(message)
    end
  end
end
