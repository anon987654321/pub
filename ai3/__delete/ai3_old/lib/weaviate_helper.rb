# frozen_string_literal: true

# WeaviateHelper: Provides methods to interact with the Weaviate vector database
require 'net/http'
require 'json'

class WeaviateHelper
  def initialize
    @base_uri = ENV.fetch('WEAVIATE_BASE_URI', nil)
    @api_key = ENV.fetch('WEAVIATE_API_KEY', nil)
  end

  def add_object(data)
    uri = URI("#{@base_uri}/v1/objects")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Post.new(uri.path, {
                                    'Content-Type' => 'application/json',
                                    'Authorization' => "Bearer #{@api_key}"
                                  })
    request.body = data.to_json

    response = http.request(request)
    handle_response(response)
  end

  def get_object_by_id(object_id)
    uri = URI("#{@base_uri}/v1/objects/#{object_id}")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Get.new(uri.path, {
                                   'Content-Type' => 'application/json',
                                   'Authorization' => "Bearer #{@api_key}"
                                 })

    response = http.request(request)
    handle_response(response)
  end

  def query_vector_search(vector, limit = 10)
    uri = URI("#{@base_uri}/v1/graphql")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Post.new(uri.path, {
                                    'Content-Type' => 'application/json',
                                    'Authorization' => "Bearer #{@api_key}"
                                  })
    query = {
      query: "
        {
          Get {
            Objects(nearVector: {vector: #{vector}, certainty: 0.7}, limit: #{limit}) {
              uuid
              class
              properties
            }
          }
        }
      "
    }
    request.body = query.to_json

    response = http.request(request)
    handle_response(response)
  end

  private

  def handle_response(response)
    if response.is_a?(Net::HTTPSuccess)
      JSON.parse(response.body, symbolize_names: true)
    else
      puts "Error: #{response.code} - #{response.message}"
      puts response.body
      nil
    end
  end
end
