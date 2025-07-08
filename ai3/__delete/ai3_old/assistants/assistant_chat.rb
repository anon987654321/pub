
require 'langchain'
require 'dotenv/load'
require 'reline'

class MultiAssistantChat
  def initialize
    @assistants = {
      'legal' => 'You are a legal assistant. Help with lawsuit matters.',
      'architect' => 'You are an architect assistant. Help design buildings and cities.',
      'music' => 'You are a music assistant. Help create tracks and artists.',
      'manufacturing' => 'You are a manufacturing assistant. Help design space planes and 3D print cars.'
    }
    @active_sessions = {}  # Store active tasks across assistants
    puts "Multi-Assistant Chat Initialized."
  end

  def start
    loop do
      print 'Assistant (legal, architect, music, manufacturing): '
      assistant_type = Reline.readline.strip.downcase
      break if assistant_type == 'exit'

      if @assistants.key?(assistant_type)
        session_manager(assistant_type)  # Manage session tasks
        dynamic_suggestions(assistant_type)
        assistant_chat(assistant_type)
      else
        puts "Invalid assistant type. Did you mean one of these: legal, architect, music, manufacturing?"
      end
    end
  end

  # Add session management to track active tasks
  def session_manager(type)
    @active_sessions[type] ||= []
    puts "You have #{@active_sessions[type].size} active tasks in the #{type.capitalize} Assistant."
  end

  # Add dynamic suggestions based on user history
  def dynamic_suggestions(type)
    suggestions = {
      'legal' => "You can ask about cases, court documents, or legal summaries.",
      'architect' => "You can design cities, skyscrapers, or urban plans.",
      'music' => "You can generate tracks, create artists, or experiment with genres.",
      'manufacturing' => "You can design space planes, print cars, or prototype products."
    }
    history = @active_sessions[type].last || "Start a new task!"
    puts "Last task: #{history}. Suggestion: #{suggestions[type]}"
  end

  def assistant_chat(type)
    openai = Langchain::LLM::OpenAI.new(api_key: ENV['OPENAI_API_KEY'])
    thread = Langchain::Thread.new
    assistant = Langchain::Assistant.new(
      llm: openai,
      thread: thread,
      instructions: @assistants[type]
    )
    puts "#{type.capitalize} Assistant Chat started. Type 'exit' to end."

    loop do
      print 'You: '
      input = Reline.readline.strip
      break if input.downcase == 'exit'

      response = assistant.ask(input)
      @active_sessions[type] << input  # Log the task to active session
      puts "#{type.capitalize} Assistant: #{response}"
    end
  end
end

def enhanced_dynamic_suggestions(user_input)
  suggestions = {
    'legal' => "You might want to ask about legal precedents or court document templates.",
    'architect' => "You can design cities, skyscrapers, or use sustainability models.",
    'music' => "Try generating a track inspired by an artist or genre you like.",
    'manufacturing' => "Prototype space planes, cars, or other products."
  }

  suggestion = suggestions.find { |key, _| user_input.downcase.include?(key) }
  if suggestion
    puts "Suggestion: #{suggestion[1]}"
  else
    puts "No specific suggestions, but feel free to ask anything!"
  end
end
