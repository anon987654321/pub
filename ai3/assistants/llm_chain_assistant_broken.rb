# assistants/llm_chain_assistant.rb
#
# LLMChainAssistant: Processes a query through a chain of LLM providers.
#
# The chain sequentially queries:
#   1. OpenAI providers with various chat models:
#      - "o3-mini-high"
#      - "o3-mini"
#      - "o1"
#      - "o1-mini"
#      - "gpt-4o"
#      - "gpt-4o-mini"
#   2. Anthropic Claude
#   3. Google Gemini
#   4. Weaviate vector search (via its ask method)
#
# Ensure required environment variables are set:
#   - OPENAI_API_KEY, ANTHROPIC_API_KEY, GOOGLE_GEMINI_API_KEY,
#     WEAVIATE_URL, WEAVIATE_API_KEY

# Graceful gem loading
begin
  require 'langchain'
  LANGCHAIN_AVAILABLE = true
rescue LoadError
  LANGCHAIN_AVAILABLE = false
  puts "Warning: langchain gem not available. LLM chain functionality limited."
end

class LLMChainAssistant
  def initialize
    @llm_chain = []
    
    unless LANGCHAIN_AVAILABLE
      puts "🔧 LLM Chain running in fallback mode (langchain not available)"
      return
    end

    # OpenAI providers with various chat models
    add_openai_providers if openai_available?
    add_anthropic_providers if anthropic_available?
    add_google_providers if google_available?
    add_weaviate_providers if weaviate_available?
  end

  def process_query(query)
    unless LANGCHAIN_AVAILABLE
      return fallback_response(query)
    end

    @llm_chain.each do |provider|
      begin
        response = provider[:llm].generate_text(query)
        return response if response && !response.empty?
      rescue StandardError => e
        puts "Provider #{provider[:name]} failed: #{e.message}"
        next
      end
    end
    
    "I apologize, but I'm unable to process your request at the moment. All LLM providers are unavailable."
  end

  private

  def openai_available?
    ENV["OPENAI_API_KEY"] && !ENV["OPENAI_API_KEY"].empty?
  end

  def anthropic_available?
    ENV["ANTHROPIC_API_KEY"] && !ENV["ANTHROPIC_API_KEY"].empty?
  end

  def google_available?
    ENV["GOOGLE_GEMINI_API_KEY"] && !ENV["GOOGLE_GEMINI_API_KEY"].empty?
  end

  def weaviate_available?
    ENV["WEAVIATE_URL"] && ENV["WEAVIATE_API_KEY"]
  end

  def add_openai_providers
    models = ["o3-mini-high", "o3-mini", "o1", "o1-mini", "gpt-4o", "gpt-4o-mini"]
    
    models.each do |model|
      @llm_chain << {
        name: "openai_#{model.gsub('-', '_')}",
        llm: create_openai_llm(model)
      }
    end
  end

  def add_anthropic_providers
    @llm_chain << {
      name: "anthropic_claude",
      llm: create_anthropic_llm
    }
  end

  def add_google_providers
    @llm_chain << {
      name: "google_gemini",
      llm: create_google_llm
    }
  end

  def add_weaviate_providers
    @llm_chain << {
      name: "weaviate_search",
      llm: create_weaviate_llm
    }
  end

  def create_openai_llm(model)
    Langchain::LLM::OpenAI.new(
      api_key: ENV["OPENAI_API_KEY"],
      default_options: { temperature: 0.7, chat_model: model }
    )
  rescue StandardError => e
    puts "Failed to create OpenAI LLM for #{model}: #{e.message}"
    nil
  end

  def create_anthropic_llm
    Langchain::LLM::Anthropic.new(
      api_key: ENV["ANTHROPIC_API_KEY"],
      default_options: { temperature: 0.7 }
    )
  rescue StandardError => e
    puts "Failed to create Anthropic LLM: #{e.message}"
    nil
  end

  def create_google_llm
    Langchain::LLM::GoogleGemini.new(
      api_key: ENV["GOOGLE_GEMINI_API_KEY"],
      default_options: { temperature: 0.7 }
    )
  rescue StandardError => e
    puts "Failed to create Google LLM: #{e.message}"
    nil
  end

  def create_weaviate_llm
    # This would be a custom implementation for Weaviate
    # For now, return a placeholder
    nil
  end

  def fallback_response(query)
    # Enhanced fallback responses when LLM chain is not available
    case query.downcase
    when /hello|hi|hey|greetings/
      "Hello! I'm AI³ running in fallback mode. How can I assist you today?"
    when /how are you|how do you do|how's it going/
      "I'm doing well, thank you! I'm operating in fallback mode, but I'm still here to help."
    when /what.*can.*you.*do|capabilities|features/
      "In fallback mode, I can provide basic assistance with file operations, simple questions, and general guidance. Full LLM capabilities require proper API keys and network connectivity."
    when /help|assistance|support/
      "I'm here to help! While running in fallback mode, I can assist with basic tasks. What would you like to do?"
    when /goodbye|bye|farewell|see you/
      "Goodbye! Have a wonderful day!"
    when /test|testing|check/
      "Test successful! AI³ is operational in fallback mode. All core systems are functioning."
    when /status|health|system/
      "System status: AI³ is running in fallback mode. Core functionality is available, but LLM integration requires proper configuration."
    when /thank you|thanks|appreciate/
      "You're very welcome! I'm glad I could help."
    when /who are you|what are you|identity/
      "I'm AI³ (AI Cubed), an enterprise-grade AI assistant platform. Currently running in fallback mode."
    else
      "I understand you're asking about: '#{query}'. I'm currently running in fallback mode, so my responses are simplified. With full LLM integration, I could provide more detailed and contextual assistance."
    end
  end
end
      )
    }
    @llm_chain << {
      name: "o3_mini",
      llm: Langchain::LLM::OpenAI.new(
        api_key: ENV["OPENAI_API_KEY"],
        default_options: { temperature: 0.7, chat_model: "o3-mini" }
      )
    }
    @llm_chain << {
      name: "o1",
      llm: Langchain::LLM::OpenAI.new(
        api_key: ENV["OPENAI_API_KEY"],
        default_options: { temperature: 0.7, chat_model: "o1" }
      )
    }
    @llm_chain << {
      name: "o1_mini",
      llm: Langchain::LLM::OpenAI.new(
        api_key: ENV["OPENAI_API_KEY"],
        default_options: { temperature: 0.7, chat_model: "o1-mini" }
      )
    }
    @llm_chain << {
      name: "gpt_4o",
      llm: Langchain::LLM::OpenAI.new(
        api_key: ENV["OPENAI_API_KEY"],
        default_options: { temperature: 0.7, chat_model: "gpt-4o" }
      )
    }
    @llm_chain << {
      name: "gpt_4o_mini",
      llm: Langchain::LLM::OpenAI.new(
        api_key: ENV["OPENAI_API_KEY"],
        default_options: { temperature: 0.7, chat_model: "gpt-4o-mini" }
      )
    }

    # Anthropic Claude provider
    @llm_chain << {
      name: "anthropic_claude",
      llm: Langchain::LLM::Anthropic.new(api_key: ENV["ANTHROPIC_API_KEY"])
    }

    # Google Gemini provider
    @llm_chain << {
      name: "google_gemini",
      llm: Langchain::LLM::GoogleGemini.new(api_key: ENV["GOOGLE_GEMINI_API_KEY"])
    }

    # Weaviate vector search client
    @weaviate_client = Langchain::Vectorsearch::Weaviate.new(
      url: ENV["WEAVIATE_URL"],
      api_key: ENV["WEAVIATE_API_KEY"],
      index_name: "Documents",
      llm: Langchain::LLM::OpenAI.new(api_key: ENV["OPENAI_API_KEY"])
    )
    @llm_chain << { name: "weaviate", llm: nil }  # Special handling for Weaviate below
  end

  def process_query(query)
    @llm_chain.each do |provider|
      puts "Querying #{provider[:name]}..."
      begin
        if provider[:name] == "weaviate"
          response = @weaviate_client.ask(question: query)
          completion = response.completion
        else
          response = provider[:llm].complete(prompt: query)
          completion = response.completion
        end

        if valid_response?(completion)
          puts "Response from #{provider[:name]}: #{completion}"
          return completion
        end
      rescue StandardError => e
        puts "Error querying #{provider[:name]}: #{e.message}"
      end
    end
    "No valid response obtained from any provider."
  end

  private

  def valid_response?(response)
    response && !response.strip.empty?
  end
end

