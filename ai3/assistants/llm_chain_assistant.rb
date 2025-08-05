# assistants/llm_chain_assistant.rb
#
# LLMChainAssistant: Processes a query through a chain of LLM providers.
# Enhanced version with graceful fallbacks when dependencies are unavailable

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

    # Only initialize providers if API keys are available
    add_providers_if_available
  end

  def process_query(query)
    unless LANGCHAIN_AVAILABLE
      return fallback_response(query)
    end

    return fallback_response(query) if @llm_chain.empty?

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

  def add_providers_if_available
    if ENV["OPENAI_API_KEY"] && !ENV["OPENAI_API_KEY"].empty?
      add_openai_providers
    end
    
    if ENV["ANTHROPIC_API_KEY"] && !ENV["ANTHROPIC_API_KEY"].empty?
      add_anthropic_providers
    end
    
    puts "Initialized LLM chain with #{@llm_chain.size} providers"
  end

  def add_openai_providers
    models = ["gpt-4", "gpt-3.5-turbo"]
    
    models.each do |model|
      begin
        @llm_chain << {
          name: "openai_#{model.gsub('-', '_')}",
          llm: Langchain::LLM::OpenAI.new(
            api_key: ENV["OPENAI_API_KEY"],
            default_options: { temperature: 0.7, chat_model: model }
          )
        }
      rescue StandardError => e
        puts "Failed to create OpenAI LLM for #{model}: #{e.message}"
      end
    end
  end

  def add_anthropic_providers
    begin
      @llm_chain << {
        name: "anthropic_claude",
        llm: Langchain::LLM::Anthropic.new(
          api_key: ENV["ANTHROPIC_API_KEY"],
          default_options: { temperature: 0.7 }
        )
      }
    rescue StandardError => e
      puts "Failed to create Anthropic LLM: #{e.message}"
    end
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
    when /weather/
      "I'm sorry, I don't have access to current weather data in fallback mode. With full LLM integration, I could help you find weather information."
    when /time|date/
      "The current time is #{Time.now.strftime('%Y-%m-%d %H:%M:%S')}."
    when /math|calculate|compute/
      "I can help with basic calculations in fallback mode. What would you like me to calculate?"
    else
      "I understand you're asking about: '#{query}'. I'm currently running in fallback mode, so my responses are simplified. With full LLM integration, I could provide more detailed and contextual assistance."
    end
  end
end