# frozen_string_literal: true


require_relative 'llm_wrapper'
require_relative 'file_system_tool'
require_relative 'universal_scraper'

# § Assistantapi

class AssistantAPI
  def initialize(llm:)
  begin
    # TODO: Refactor initialize - exceeds 20 line limit (32 lines)
      @llm_wrapper = LLMWrapper.new
      @scraper = UniversalScraper.new
      @file_system_tool = FileSystemTool.new
    end
  
    def process_request(request)
      case request[:action]
      when 'scrape_data'
        scrape_data(request[:urls])
      when 'query_llm'
        query_llm(request[:prompt])
      when 'create_file'
        create_file(request[:file_path], request[:content])
      else
        "Unknown action: #{request[:action]}"
      end
    end
  
    def scrape_data(urls)
      @scraper.scrape(urls)
    end
  
    def query_llm(prompt)
      response = @llm_wrapper.query_openai(prompt)
      puts "Assistant Response: #{response}"
    end
  
    def create_file(file_path, content)
      @file_system_tool.create_file(file_path, content)
    end
  rescue StandardError => e
    # TODO: Add proper error handling
    raise e
  end
end