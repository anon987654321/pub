# frozen_string_literal: true

# WeaviateHelper: Provides methods to interact with the Weaviate vector database
require 'net/http'
require 'json'
require 'uri'

class WeaviateHelper
  def initialize
    @base_uri = ENV.fetch('WEAVIATE_BASE_URI', 'http://localhost:8080')
    @api_key = ENV.fetch('WEAVIATE_API_KEY', nil)
    @timeout = 30
  end

  def add_object(data, class_name = 'Document')
    uri = URI("#{@base_uri}/v1/objects")
    
    object_data = {
      class: class_name,
      properties: data
    }
    
    response = make_request(uri, :post, object_data)
    handle_response(response)
  end

  def get_object_by_id(object_id)
    uri = URI("#{@base_uri}/v1/objects/#{object_id}")
    response = make_request(uri, :get)
    handle_response(response)
  end

  def search_objects(query, class_name = 'Document', limit = 10)
    uri = URI("#{@base_uri}/v1/graphql")
    
    graphql_query = {
      query: build_search_query(query, class_name, limit)
    }
    
    response = make_request(uri, :post, graphql_query)
    handle_response(response)
  end

  def vector_search(vector, class_name = 'Document', limit = 10, certainty = 0.7)
    uri = URI("#{@base_uri}/v1/graphql")
    
    graphql_query = {
      query: build_vector_search_query(vector, class_name, limit, certainty)
    }
    
    response = make_request(uri, :post, graphql_query)
    handle_response(response)
  end

  def create_class(class_definition)
    uri = URI("#{@base_uri}/v1/schema")
    response = make_request(uri, :post, class_definition)
    handle_response(response)
  end

  def delete_object(object_id)
    uri = URI("#{@base_uri}/v1/objects/#{object_id}")
    response = make_request(uri, :delete)
    handle_response(response)
  end

  def batch_import(objects, class_name = 'Document')
    uri = URI("#{@base_uri}/v1/batch/objects")
    
    batch_data = {
      objects: objects.map do |obj|
        {
          class: class_name,
          properties: obj
        }
      end
    }
    
    response = make_request(uri, :post, batch_data)
    handle_response(response)
  end

  def check_if_indexed(url)
    # Search for objects with this URL
    search_result = search_objects("url:#{url}")
    
    return false unless search_result && search_result['data']
    
    # Check if any results were found
    get_path = ['data', 'Get', 'Document']
    results = search_result.dig(*get_path)
    
    results && results.any?
  end

  def get_schema
    uri = URI("#{@base_uri}/v1/schema")
    response = make_request(uri, :get)
    handle_response(response)
  end

  def health_check
    uri = URI("#{@base_uri}/v1/.well-known/ready")
    response = make_request(uri, :get)
    response.code == '200'
  rescue StandardError
    false
  end

  private

  def make_request(uri, method, data = nil)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = uri.scheme == 'https'
    http.read_timeout = @timeout
    http.open_timeout = @timeout

    case method
    when :get
      request = Net::HTTP::Get.new(uri.request_uri)
    when :post
      request = Net::HTTP::Post.new(uri.request_uri)
      request.body = data.to_json if data
    when :delete
      request = Net::HTTP::Delete.new(uri.request_uri)
    else
      raise ArgumentError, "Unsupported HTTP method: #{method}"
    end

    # Set headers
    request['Content-Type'] = 'application/json'
    request['Authorization'] = "Bearer #{@api_key}" if @api_key

    http.request(request)
  rescue StandardError => e
    raise ConnectionError, "Failed to connect to Weaviate: #{e.message}"
  end

  def handle_response(response)
    case response.code
    when '200', '201'
      JSON.parse(response.body)
    when '404'
      nil
    when '400'
      error_data = JSON.parse(response.body) rescue {}
      raise ArgumentError, "Bad request: #{error_data['error'] || response.body}"
    when '401'
      raise AuthenticationError, 'Authentication failed - check API key'
    when '500'
      raise ServerError, 'Weaviate server error'
    else
      raise APIError, "Unexpected response code: #{response.code}"
    end
  rescue JSON::ParserError
    raise ResponseError, "Invalid JSON response: #{response.body}"
  end

  def build_search_query(query, class_name, limit)
    <<~GRAPHQL
      {
        Get {
          #{class_name}(
            where: {
              operator: Or
              operands: [
                {
                  path: ["content"]
                  operator: Like
                  valueText: "*#{query}*"
                }
                {
                  path: ["title"] 
                  operator: Like
                  valueText: "*#{query}*"
                }
              ]
            }
            limit: #{limit}
          ) {
            content
            title
            url
            _additional {
              id
              score
            }
          }
        }
      }
    GRAPHQL
  end

  def build_vector_search_query(vector, class_name, limit, certainty)
    vector_str = vector.map(&:to_s).join(',')
    
    <<~GRAPHQL
      {
        Get {
          #{class_name}(
            nearVector: {
              vector: [#{vector_str}]
              certainty: #{certainty}
            }
            limit: #{limit}
          ) {
            content
            title
            url
            _additional {
              id
              certainty
              vector
            }
          }
        }
      }
    GRAPHQL
  end

  # Custom error classes
  class ConnectionError < StandardError; end
  class AuthenticationError < StandardError; end
  class ServerError < StandardError; end
  class APIError < StandardError; end
  class ResponseError < StandardError; end
end