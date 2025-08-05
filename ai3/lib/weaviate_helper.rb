# frozen_string_literal: true

# WeaviateHelper: Provides methods to interact with the Weaviate vector database
# Enhanced version from backup with improved error handling and logging
require 'net/http'
require 'json'
require 'logger'

class WeaviateHelper
  attr_reader :logger

  def initialize(config = {})
    @base_uri = config[:base_uri] || ENV.fetch('WEAVIATE_BASE_URI', 'http://localhost:8080')
    @api_key = config[:api_key] || ENV.fetch('WEAVIATE_API_KEY', nil)
    @logger = config[:logger] || Logger.new(STDOUT)
    @timeout = config[:timeout] || 30
    
    # Validate configuration
    validate_configuration
  end

  # Add an object to Weaviate
  def add_object(data, class_name = 'Document')
    uri = URI("#{@base_uri}/v1/objects")
    
    # Prepare object with class
    object_data = {
      class: class_name,
      properties: data
    }
    
    begin
      response = make_request(uri, 'POST', object_data)
      handle_response(response, 'add_object')
    rescue StandardError => e
      @logger.error("Failed to add object: #{e.message}")
      nil
    end
  end

  # Get object by ID
  def get_object_by_id(object_id)
    uri = URI("#{@base_uri}/v1/objects/#{object_id}")
    
    begin
      response = make_request(uri, 'GET')
      handle_response(response, 'get_object_by_id')
    rescue StandardError => e
      @logger.error("Failed to get object #{object_id}: #{e.message}")
      nil
    end
  end

  # Vector similarity search
  def query_vector_search(vector, class_name = 'Document', limit = 10, certainty = 0.7)
    uri = URI("#{@base_uri}/v1/graphql")
    
    query = build_vector_search_query(vector, class_name, limit, certainty)
    
    begin
      response = make_request(uri, 'POST', { query: query })
      result = handle_response(response, 'query_vector_search')
      parse_search_results(result)
    rescue StandardError => e
      @logger.error("Failed to execute vector search: #{e.message}")
      []
    end
  end

  # Search by text (using Weaviate's text search)
  def search_by_text(text, class_name = 'Document', limit = 10)
    uri = URI("#{@base_uri}/v1/graphql")
    
    query = build_text_search_query(text, class_name, limit)
    
    begin
      response = make_request(uri, 'POST', { query: query })
      result = handle_response(response, 'search_by_text')
      parse_search_results(result)
    rescue StandardError => e
      @logger.error("Failed to execute text search: #{e.message}")
      []
    end
  end

  # Check if URL is already indexed
  def check_if_indexed(url, class_name = 'Document')
    uri = URI("#{@base_uri}/v1/graphql")
    
    query = build_url_check_query(url, class_name)
    
    begin
      response = make_request(uri, 'POST', { query: query })
      result = handle_response(response, 'check_if_indexed')
      
      # Check if any objects were returned
      objects = result.dig('data', 'Get', class_name) || []
      !objects.empty?
    rescue StandardError => e
      @logger.error("Failed to check if URL indexed: #{e.message}")
      false
    end
  end

  # Add document with metadata
  def add_document(content:, url:, title: nil, metadata: {})
    document_data = {
      content: content,
      url: url,
      title: title || extract_title_from_url(url),
      indexed_at: Time.now.iso8601,
      content_length: content.length,
      **metadata
    }
    
    add_object(document_data, 'Document')
  end

  # Batch operations
  def batch_add_objects(objects, class_name = 'Document')
    uri = URI("#{@base_uri}/v1/batch/objects")
    
    batch_data = {
      objects: objects.map do |data|
        {
          class: class_name,
          properties: data
        }
      end
    }
    
    begin
      response = make_request(uri, 'POST', batch_data)
      handle_response(response, 'batch_add_objects')
    rescue StandardError => e
      @logger.error("Failed to batch add objects: #{e.message}")
      nil
    end
  end

  # Get schema information
  def get_schema
    uri = URI("#{@base_uri}/v1/schema")
    
    begin
      response = make_request(uri, 'GET')
      handle_response(response, 'get_schema')
    rescue StandardError => e
      @logger.error("Failed to get schema: #{e.message}")
      nil
    end
  end

  # Health check
  def health_check
    uri = URI("#{@base_uri}/v1/.well-known/ready")
    
    begin
      response = make_request(uri, 'GET', nil, timeout: 5)
      response.is_a?(Net::HTTPSuccess)
    rescue StandardError => e
      @logger.error("Health check failed: #{e.message}")
      false
    end
  end

  private

  # Validate configuration
  def validate_configuration
    if @base_uri.nil? || @base_uri.empty?
      raise ArgumentError, 'Weaviate base URI is required'
    end
    
    @logger.info("WeaviateHelper initialized with base URI: #{@base_uri}")
    @logger.info("API key configured: #{@api_key ? 'Yes' : 'No'}")
  end

  # Make HTTP request
  def make_request(uri, method, data = nil, timeout: nil)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = uri.scheme == 'https'
    http.read_timeout = timeout || @timeout
    
    headers = {
      'Content-Type' => 'application/json',
      'User-Agent' => 'AI3-WeaviateHelper/1.0'
    }
    
    headers['Authorization'] = "Bearer #{@api_key}" if @api_key
    
    request = case method.upcase
              when 'GET'
                Net::HTTP::Get.new(uri.path, headers)
              when 'POST'
                req = Net::HTTP::Post.new(uri.path, headers)
                req.body = data.to_json if data
                req
              else
                raise ArgumentError, "Unsupported HTTP method: #{method}"
              end
    
    @logger.debug("Making #{method} request to #{uri}")
    http.request(request)
  end

  # Handle HTTP response
  def handle_response(response, operation)
    case response
    when Net::HTTPSuccess
      @logger.debug("#{operation} successful")
      response.body.empty? ? {} : JSON.parse(response.body, symbolize_names: true)
    else
      error_msg = "#{operation} failed: #{response.code} - #{response.message}"
      @logger.error(error_msg)
      @logger.error("Response body: #{response.body}") if response.body
      raise StandardError, error_msg
    end
  end

  # Build vector search GraphQL query
  def build_vector_search_query(vector, class_name, limit, certainty)
    <<~GRAPHQL
      {
        Get {
          #{class_name}(
            nearVector: {
              vector: #{vector.to_json}
              certainty: #{certainty}
            }
            limit: #{limit}
          ) {
            _additional {
              id
              certainty
              distance
            }
            content
            url
            title
            indexed_at
          }
        }
      }
    GRAPHQL
  end

  # Build text search GraphQL query
  def build_text_search_query(text, class_name, limit)
    escaped_text = text.gsub('"', '\\"')
    
    <<~GRAPHQL
      {
        Get {
          #{class_name}(
            nearText: {
              concepts: ["#{escaped_text}"]
            }
            limit: #{limit}
          ) {
            _additional {
              id
              certainty
              distance
            }
            content
            url
            title
            indexed_at
          }
        }
      }
    GRAPHQL
  end

  # Build URL check GraphQL query
  def build_url_check_query(url, class_name)
    escaped_url = url.gsub('"', '\\"')
    
    <<~GRAPHQL
      {
        Get {
          #{class_name}(
            where: {
              path: ["url"]
              operator: Equal
              valueString: "#{escaped_url}"
            }
            limit: 1
          ) {
            url
            indexed_at
          }
        }
      }
    GRAPHQL
  end

  # Parse search results from GraphQL response
  def parse_search_results(result)
    return [] unless result && result['data'] && result['data']['Get']
    
    # Get the first class results (assuming single class search)
    class_results = result['data']['Get'].values.first || []
    
    class_results.map do |item|
      {
        id: item.dig('_additional', 'id'),
        content: item['content'],
        url: item['url'],
        title: item['title'],
        indexed_at: item['indexed_at'],
        certainty: item.dig('_additional', 'certainty'),
        distance: item.dig('_additional', 'distance')
      }
    end
  end

  # Extract title from URL for fallback
  def extract_title_from_url(url)
    uri = URI.parse(url)
    uri.host&.gsub(/^www\./, '') || url
  rescue URI::InvalidURIError
    url
  end
end