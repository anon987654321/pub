# frozen_string_literal: true

# assistant_chat.rb - Multi-Assistant Session Management
# Enhanced version from backup with cognitive orchestration integration

require 'logger'
require 'json'
require_relative '../lib/enhanced_session_manager'
require_relative '../lib/cognitive_orchestrator'

class AssistantChat
  attr_reader :assistants, :active_sessions, :session_manager, :cognitive_orchestrator

  def initialize(config = {})
    @config = default_config.merge(config)
    @logger = @config[:logger] || Logger.new(STDOUT)
    
    # Initialize core components
    @cognitive_orchestrator = CognitiveOrchestrator.new
    @session_manager = EnhancedSessionManager.new(cognitive_monitor: @cognitive_orchestrator)
    
    # Initialize assistant registry
    @assistants = initialize_assistants
    @active_sessions = {}
    
    @logger.info("AssistantChat initialized with #{@assistants.size} assistants")
  end

  # Start interactive multi-assistant chat
  def start_interactive_chat
    display_welcome
    
    loop do
      # Check cognitive health
      check_cognitive_health
      
      # Get assistant selection
      assistant_type = prompt_assistant_selection
      break if assistant_type == 'exit'
      
      if @assistants.key?(assistant_type)
        manage_assistant_session(assistant_type)
      else
        puts "❌ Invalid assistant type. Available: #{@assistants.keys.join(', ')}"
      end
    end
    
    puts "👋 Goodbye!"
  end

  # Chat with specific assistant
  def chat_with_assistant(assistant_type, message, context = {})
    return { error: "Unknown assistant: #{assistant_type}" } unless @assistants.key?(assistant_type)
    
    assistant = @assistants[assistant_type]
    
    begin
      # Get or create session
      session = @session_manager.get_session("#{assistant_type}_session")
      
      # Add cognitive context
      enhanced_context = context.merge({
        cognitive_state: @cognitive_orchestrator.cognitive_state,
        session_context: session[:context],
        assistant_type: assistant_type
      })
      
      # Generate response
      response = assistant[:instance].respond(message, enhanced_context)
      
      # Update session
      @session_manager.update_session("#{assistant_type}_session", {
        last_message: message,
        last_response: response,
        interaction_count: (session[:context][:interaction_count] || 0) + 1
      })
      
      # Update cognitive load
      complexity = assess_message_complexity(message)
      @cognitive_orchestrator.add_concept(message[0..50], complexity * 0.1)
      
      {
        assistant: assistant_type,
        response: response,
        cognitive_load: @cognitive_orchestrator.current_load,
        session_id: session[:session_id]
      }
      
    rescue StandardError => e
      @logger.error("Error in assistant chat: #{e.message}")
      { error: "Assistant error: #{e.message}" }
    end
  end

  # Switch between assistants with context transfer
  def switch_assistant(from_type, to_type, transfer_context: true)
    return false unless @assistants.key?(from_type) && @assistants.key?(to_type)
    
    if transfer_context
      from_session = @session_manager.get_session("#{from_type}_session")
      to_session = @session_manager.get_session("#{to_type}_session")
      
      # Transfer relevant context
      transfer_data = {
        previous_assistant: from_type,
        transferred_context: from_session[:context][:last_message],
        transfer_timestamp: Time.now
      }
      
      @session_manager.update_session("#{to_type}_session", transfer_data)
      @logger.info("Context transferred from #{from_type} to #{to_type}")
    end
    
    true
  end

  # Get status of all assistants
  def assistant_status
    status = {}
    
    @assistants.each do |type, assistant|
      session = @session_manager.get_session("#{type}_session")
      
      status[type] = {
        name: assistant[:name],
        description: assistant[:description],
        capabilities: assistant[:capabilities],
        session_active: !session[:context].empty?,
        interaction_count: session[:context][:interaction_count] || 0,
        last_active: session[:timestamp],
        cognitive_load: calculate_assistant_cognitive_load(type)
      }
    end
    
    status
  end

  # Collaborative mode - multiple assistants working together
  def collaborative_chat(assistants_list, message, coordination_strategy: :sequential)
    results = []
    
    case coordination_strategy
    when :sequential
      assistants_list.each do |assistant_type|
        result = chat_with_assistant(assistant_type, message)
        results << result
        
        # Use previous response as context for next assistant
        message = "Building on previous assistant's response: #{result[:response]}\n\nOriginal query: #{message}"
      end
      
    when :parallel
      # Run assistants in parallel (simplified)
      assistants_list.each do |assistant_type|
        result = chat_with_assistant(assistant_type, message)
        results << result
      end
      
    when :consensus
      # Get responses from all assistants and synthesize
      individual_responses = assistants_list.map do |assistant_type|
        chat_with_assistant(assistant_type, message)
      end
      
      # Create consensus response
      consensus_message = synthesize_consensus(individual_responses)
      results = individual_responses + [{ 
        assistant: 'consensus', 
        response: consensus_message,
        source_assistants: assistants_list
      }]
    end
    
    results
  end

  private

  def default_config
    {
      logger: nil,
      max_sessions: 20,
      enable_context_transfer: true,
      cognitive_monitoring: true
    }
  end

  def initialize_assistants
    {
      'casual' => {
        name: 'Casual Assistant',
        description: 'General conversation and basic assistance',
        capabilities: ['conversation', 'general_help', 'information'],
        instance: load_assistant('casual_assistant')
      },
      'legal' => {
        name: 'Legal Assistant',
        description: 'Legal advice and document assistance',
        capabilities: ['legal_advice', 'document_review', 'case_analysis'],
        instance: load_assistant('lawyer_assistant')
      },
      'architect' => {
        name: 'Architect Assistant',
        description: 'Building and urban design assistance',
        capabilities: ['design', 'planning', 'structural_analysis'],
        instance: load_assistant('architect_assistant')
      },
      'music' => {
        name: 'Music Assistant',
        description: 'Music creation and audio engineering',
        capabilities: ['composition', 'production', 'audio_engineering'],
        instance: load_assistant('musicians')
      },
      'manufacturing' => {
        name: 'Manufacturing Assistant',
        description: 'Product design and manufacturing processes',
        capabilities: ['product_design', '3d_modeling', 'manufacturing_planning'],
        instance: load_assistant('material_design_assistant')
      },
      'security' => {
        name: 'Security Assistant',
        description: 'Cybersecurity and penetration testing',
        capabilities: ['security_analysis', 'penetration_testing', 'vulnerability_assessment'],
        instance: load_assistant('hacker')
      },
      'seo' => {
        name: 'SEO Assistant',
        description: 'Search engine optimization and content strategy',
        capabilities: ['seo_analysis', 'content_optimization', 'keyword_research'],
        instance: load_assistant('seo_assistant')
      },
      'social_media' => {
        name: 'Social Media Assistant',
        description: 'Social media management and automation',
        capabilities: ['content_creation', 'engagement', 'automation'],
        instance: load_assistant('influencer_assistant')
      }
    }
  end

  def load_assistant(assistant_file)
    begin
      require_relative "#{assistant_file}"
      
      # Try to instantiate the assistant class
      class_name = assistant_file.split('_').map(&:capitalize).join('')
      if Object.const_defined?(class_name)
        Object.const_get(class_name).new
      else
        # Fallback to a simple responder
        SimpleAssistant.new(assistant_file)
      end
    rescue LoadError => e
      @logger.warn("Could not load assistant #{assistant_file}: #{e.message}")
      SimpleAssistant.new(assistant_file)
    end
  end

  def display_welcome
    puts <<~WELCOME
      🤖 AI³ Multi-Assistant Chat System
      
      Available Assistants:
      #{@assistants.map { |type, info| "  • #{type}: #{info[:description]}" }.join("\n")}
      
      Commands:
      - Type assistant name to chat
      - 'status' for system status
      - 'switch <from> <to>' to switch assistants
      - 'collab <assistant1,assistant2>' for collaborative mode
      - 'exit' to quit
      
    WELCOME
  end

  def prompt_assistant_selection
    print "🔹 Select assistant (or command): "
    input = gets.chomp.strip.downcase
    
    # Handle special commands
    case input
    when 'status'
      display_status
      return prompt_assistant_selection
    when /^switch\s+(\w+)\s+(\w+)$/
      from_type, to_type = input.match(/^switch\s+(\w+)\s+(\w+)$/).captures
      switch_assistant(from_type, to_type)
      puts "✅ Switched from #{from_type} to #{to_type}"
      return prompt_assistant_selection
    when /^collab\s+(.+)$/
      assistants_list = $1.split(',').map(&:strip)
      puts "🤝 Collaborative mode with: #{assistants_list.join(', ')}"
      handle_collaborative_session(assistants_list)
      return prompt_assistant_selection
    end
    
    input
  end

  def manage_assistant_session(assistant_type)
    assistant = @assistants[assistant_type]
    session = @session_manager.get_session("#{assistant_type}_session")
    
    puts "\n💬 Chatting with #{assistant[:name]}"
    puts "📊 Previous interactions: #{session[:context][:interaction_count] || 0}"
    
    display_dynamic_suggestions(assistant_type)
    
    loop do
      print "\n#{assistant[:name]}> "
      message = gets.chomp.strip
      
      break if message.downcase == 'exit' || message.downcase == 'back'
      next if message.empty?
      
      # Process message
      result = chat_with_assistant(assistant_type, message)
      
      if result[:error]
        puts "❌ Error: #{result[:error]}"
      else
        puts "\n🤖 #{result[:response]}"
        
        # Show cognitive load if high
        if result[:cognitive_load] > 5
          puts "🧠 Cognitive load: #{result[:cognitive_load].round(1)}/7"
        end
      end
    end
  end

  def handle_collaborative_session(assistants_list)
    valid_assistants = assistants_list.select { |a| @assistants.key?(a) }
    
    if valid_assistants.empty?
      puts "❌ No valid assistants specified"
      return
    end
    
    puts "🤝 Collaborative session with: #{valid_assistants.join(', ')}"
    print "Message for collaboration: "
    message = gets.chomp.strip
    
    return if message.empty?
    
    results = collaborative_chat(valid_assistants, message, coordination_strategy: :consensus)
    
    puts "\n📊 Collaborative Results:"
    results.each do |result|
      puts "\n#{result[:assistant].upcase}: #{result[:response]}"
    end
  end

  def display_dynamic_suggestions(assistant_type)
    suggestions = {
      'casual' => 'Ask me anything! I can help with general questions and conversation.',
      'legal' => 'I can help with legal research, document review, or case analysis.',
      'architect' => 'I can assist with building design, urban planning, or structural analysis.',
      'music' => 'I can help create music, analyze tracks, or provide audio engineering advice.',
      'manufacturing' => 'I can assist with product design, 3D modeling, or manufacturing processes.',
      'security' => 'I can help with security analysis, penetration testing, or vulnerability assessment.',
      'seo' => 'I can help with SEO strategy, content optimization, or keyword research.',
      'social_media' => 'I can assist with content creation, social media strategy, or automation.'
    }
    
    puts "💡 #{suggestions[assistant_type] || 'How can I help you today?'}"
  end

  def display_status
    puts "\n📊 Assistant Status:"
    
    status = assistant_status
    status.each do |type, info|
      indicator = info[:session_active] ? "🟢" : "⚪"
      cognitive_load = info[:cognitive_load].round(1)
      
      puts "#{indicator} #{type}: #{info[:interaction_count]} interactions, load: #{cognitive_load}/7"
    end
    
    cognitive_state = @cognitive_orchestrator.cognitive_state
    puts "\n🧠 System Cognitive Load: #{cognitive_state[:load].round(1)}/7"
    puts "📈 Flow State: #{cognitive_state[:flow_state]}"
  end

  def check_cognitive_health
    if @cognitive_orchestrator.cognitive_overload?
      puts "⚠️ System cognitive overload detected. Consider taking a break or simplifying tasks."
    end
  end

  def assess_message_complexity(message)
    complexity = 1.0
    
    # Length factor
    complexity += (message.length / 100.0).clamp(0, 2)
    
    # Question complexity
    question_words = ['how', 'why', 'what', 'when', 'where', 'which', 'analyze', 'explain', 'compare']
    question_count = question_words.count { |word| message.downcase.include?(word) }
    complexity += (question_count * 0.3)
    
    # Technical terms
    technical_terms = ['algorithm', 'implementation', 'optimization', 'architecture', 'framework']
    tech_count = technical_terms.count { |term| message.downcase.include?(term) }
    complexity += (tech_count * 0.5)
    
    complexity.clamp(1.0, 5.0)
  end

  def calculate_assistant_cognitive_load(assistant_type)
    session = @session_manager.get_session("#{assistant_type}_session")
    base_load = session[:context][:interaction_count] || 0
    
    # Simple cognitive load calculation
    (base_load * 0.1).clamp(0, 7)
  end

  def synthesize_consensus(responses)
    valid_responses = responses.select { |r| !r[:error] }
    
    return "No valid responses received" if valid_responses.empty?
    
    consensus = "Consensus from #{valid_responses.size} assistants:\n\n"
    
    valid_responses.each_with_index do |response, index|
      consensus += "#{index + 1}. #{response[:assistant].capitalize}: #{response[:response]}\n\n"
    end
    
    consensus += "Summary: The assistants provided complementary perspectives on your query."
    consensus
  end
end

# Simple fallback assistant for when specific assistants can't be loaded
class SimpleAssistant
  def initialize(name)
    @name = name
  end

  def respond(message, context = {})
    "I'm the #{@name} assistant. You said: '#{message}'. This is a placeholder response as the full assistant implementation is being loaded."
  end
end