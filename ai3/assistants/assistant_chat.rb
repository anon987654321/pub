# frozen_string_literal: true

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
    @active_sessions = {} # Store active tasks across assistants
    puts 'Multi-Assistant Chat Initialized.'
  end

  def start
    loop do
      print 'Assistant (legal, architect, music, manufacturing): '
      assistant_type = Reline.readline.strip.downcase
      break if assistant_type == 'exit'

      if @assistants.key?(assistant_type)
        session_manager(assistant_type) # Manage session tasks
        dynamic_suggestions(assistant_type)
        assistant_chat(assistant_type)
      else
        puts 'Invalid assistant type. Did you mean one of these: legal, architect, music, manufacturing?'
      end
    end
  end

  private

  def session_manager(assistant_type)
    # Check for active sessions and provide context-aware suggestions
    if @active_sessions[assistant_type]
      puts "Active Task for #{assistant_type.capitalize}: #{@active_sessions[assistant_type][:task]}"
    else
      @active_sessions[assistant_type] = { task: 'New Session', started: Time.now }
    end
  end

  def dynamic_suggestions(assistant_type)
    # Use OpenAI to dynamically suggest next steps based on assistant type
    suggestions = case assistant_type
                  when 'legal'
                    ['Draft a contract', 'Research case law', 'Prepare legal brief']
                  when 'architect'
                    ['Design floor plan', 'Calculate structural load', 'Select materials']
                  when 'music'
                    ['Compose melody', 'Mix tracks', 'Master audio']
                  when 'manufacturing'
                    ['Design CAD model', 'Calculate material costs', 'Plan production']
                  end

    puts "Suggestions: #{suggestions.join(', ')}"
  end

  def assistant_chat(assistant_type)
    puts "\n--- #{assistant_type.capitalize} Assistant ---"
    loop do
      print "#{assistant_type}> "
      user_input = Reline.readline.strip
      break if user_input.downcase == 'back'

      # Update active session with current task
      @active_sessions[assistant_type][:task] = user_input

      response = llm_query(@assistants[assistant_type], user_input)
      puts "Response: #{response}\n"
    end
  end

  def llm_query(system_prompt, user_input)
    # Placeholder for LLM interaction
    "#{system_prompt} Response to: #{user_input}"
  end
end

# Allow running directly
if __FILE__ == $0
  MultiAssistantChat.new.start
end