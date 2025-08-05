# assistants/casual_assistant.rb
#
# CasualAssistant: Provides general conversation by delegating queries
# to an LLM chain that sequentially tries multiple providers.

begin
  require_relative "llm_chain_assistant"
  LLM_CHAIN_AVAILABLE = true
rescue LoadError => e
  LLM_CHAIN_AVAILABLE = false
  puts "Warning: LLM chain not available (#{e.message}). Using fallback."
end

class CasualAssistant
  def initialize
    if LLM_CHAIN_AVAILABLE
      @chain_assistant = LLMChainAssistant.new
    else
      @chain_assistant = FallbackAssistant.new
    end
  end

  def respond(input, context = {})
    puts "CasualAssistant processing your input..."
    response = @chain_assistant.process_query(input)
    puts "CasualAssistant: #{response}"
    response
  end
end

# Fallback assistant when full LLM chain is not available
class FallbackAssistant
  def initialize
    puts "🔧 Fallback assistant initialized (LLM chain not available)"
  end

  def process_query(input)
    # Simple rule-based responses for basic functionality
    case input.downcase
    when /hello|hi|hey/
      "Hello! I'm AI³ running in fallback mode. How can I help you today?"
    when /how are you|how do you do/
      "I'm doing well, thank you! I'm an AI assistant here to help you."
    when /what.*your.*name/
      "I'm AI³ (AI Cubed), an enterprise-grade AI assistant platform."
    when /help|assistance/
      "I can help with various tasks including file operations, text processing, and general assistance. What would you like to do?"
    when /goodbye|bye|see you/
      "Goodbye! Have a great day!"
    when /test|testing/
      "Test successful! AI³ system is operational in fallback mode."
    else
      "I understand you said: '#{input}'. I'm running in fallback mode, so my responses are limited. The full AI³ system with LLM integration would provide more comprehensive assistance."
    end
  end
end

