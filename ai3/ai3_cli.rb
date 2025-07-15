#!/usr/bin/env ruby
# frozen_string_literal: true

require "thor"
require "yaml"
require "dotenv"
require "i18n"
require "pastel"
require "tty-prompt"
require "tty-spinner"
require "tty-box"
require "fileutils"

# Load environment variables
Dotenv.load(".env", File.expand_path("~/.ai3_keys"))

# Setup I18n
I18n.load_path = Dir[File.join(__dir__, "config", "locales", "*.yml")]
I18n.available_locales = [:en]
I18n.default_locale = :en

# Require core AI³ components
require_relative "lib/cognitive_orchestrator"
require_relative "lib/multi_llm_manager"
require_relative "lib/enhanced_session_manager"
require_relative "lib/rag_engine"
require_relative "lib/assistant_registry"
require_relative "lib/universal_scraper"

# AI³ CLI Application with Thor framework
class AI3CLI < Thor
  VERSION = "12.3.0"

  # Class-level configuration
  class_option :config, type: :string, default: "config/config.yml", 
               desc: "Configuration file path"
  class_option :debug, type: :boolean, default: false, 
               desc: "Enable debug mode"
  class_option :verbose, type: :boolean, default: false, 
               desc: "Enable verbose output"

  attr_reader :app_config, :cognitive_orchestrator, :llm_manager, :session_manager,
              :rag_engine, :assistant_registry, :current_assistant, :prompt, :pastel

  def initialize(args = [], local_options = {}, config = {})
    super(args, local_options, config)
    
    @pastel = Pastel.new
    @prompt = TTY::Prompt.new
    
    # Load configuration
    @app_config = load_configuration(options[:config])
    
    # Setup directories first
    setup_directories
    
    # Initialize core components
    initialize_components
  end

  # Default command when no command is specified
  desc "interactive", "Start interactive AI³ session"
  def interactive
    display_welcome
    
    loop do
      begin
        # Check cognitive health
        check_cognitive_health
        
        # Get user input
        input = get_user_input
        
        # Process command
        process_interactive_command(input) unless input.nil? || input.strip.empty?
        
      rescue Interrupt
        puts "\n👋 #{I18n.t("ai3.messages.goodbye")}"
        break
      rescue StandardError => e
        handle_error(e)
      end
    end
  end

  desc "chat MESSAGE", "Chat with the current assistant"
  long_desc <<-LONGDESC
    Start a conversation with the current AI assistant. The message is processed
    through the cognitive framework to ensure optimal working memory management.
    
    The system uses a 7±2 cognitive load management approach to prevent
    information overload and maintain flow state.
    
    Examples:
      ai3 chat "Explain quantum computing"
      ai3 chat "What are the benefits of renewable energy?"
  LONGDESC
  def chat(message)
    return say("❌ Please provide a message", :red) if message.nil? || message.strip.empty?
    
    validate_input(message)
    
    # Check cognitive capacity
    complexity = cognitive_orchestrator.assess_complexity(message)
    
    if cognitive_orchestrator.cognitive_overload?
      snapshot_id = cognitive_orchestrator.trigger_circuit_breaker
      say("🧠 #{I18n.t("ai3.cognitive.circuit_breaker.activated")} (Snapshot: #{snapshot_id})", :yellow)
      return
    end

    spinner = TTY::Spinner.new("[:spinner] #{I18n.t("ai3.messages.processing")}...", format: :dots)
    spinner.auto_spin

    begin
      # Get session context
      session = session_manager.get_session("default_user")
      
      # Generate response using current assistant
      response = current_assistant.respond(message, context: session[:context])
      
      # Route through LLM manager if needed
      if response.is_a?(String) && response.include?("I'm #{current_assistant.name}")
        llm_response = llm_manager.route_query(message)
        response = llm_response[:response]
        
        if llm_response[:fallback_used]
          say("🔄 #{I18n.t("ai3.messages.fallback_activated")} (#{llm_response[:provider]})", :yellow)
        end
      end
      
      # Update session
      session_manager.update_session("default_user", {
        last_query: message,
        last_response: response,
        assistant_used: current_assistant.name
      })
      
      # Add to cognitive orchestrator
      cognitive_orchestrator.add_concept(message[0..50], complexity * 0.1)
      
      spinner.stop
      say("\n#{@pastel.green("Assistant:")} #{response}\n")
      
    rescue StandardError => e
      spinner.stop
      handle_error(e)
    end
  end

  desc "rag QUERY", "Perform retrieval-augmented generation query"
  long_desc <<-LONGDESC
    Search the knowledge base and provide enhanced responses using
    retrieval-augmented generation (RAG). This combines stored
    information with LLM capabilities for more accurate responses.
    
    Examples:
      ai3 rag "Norwegian privacy laws"
      ai3 rag "Latest research on machine learning"
  LONGDESC
  def rag(query)
    return say("❌ Please provide a query", :red) if query.nil? || query.strip.empty?
    
    validate_input(query)
    
    unless app_config.dig("rag", "enabled")
      say("❌ #{I18n.t("ai3.errors.rag_disabled")}", :red)
      return
    end

    spinner = TTY::Spinner.new("[:spinner] #{I18n.t("ai3.rag.searching")}...", format: :dots)
    spinner.auto_spin

    begin
      # Search using RAG engine
      results = rag_engine.search(query, limit: app_config.dig("rag", "max_results") || 5)
      
      spinner.stop
      
      if results.empty?
        say("❌ #{I18n.t("ai3.rag.no_results")}", :red)
        return
      end
      
      say("📚 #{I18n.t("ai3.rag.results_found", count: results.size)}\n")
      
      # Display results
      results.each_with_index do |result, index|
        say("#{@pastel.cyan("#{index + 1}.")} #{result[:content][0..200]}...")
        say("   #{@pastel.dim("Similarity: #{(result[:similarity] * 100).round(1)}%")}\n")
      end
      
      # Enhance query with RAG context and get LLM response
      context_text = results.map { |r| r[:content] }.join("\n\n")
      enhanced_query = "Based on this context: #{context_text}\n\nQuestion: #{query}"
      
      llm_response = llm_manager.route_query(enhanced_query)
      say("\n#{@pastel.green("Enhanced Response:")} #{llm_response[:response]}\n")
      
    rescue StandardError => e
      spinner.stop
      handle_error(e)
    end
  end

  desc "scrape URL", "Scrape web content and add to knowledge base"
  long_desc <<-LONGDESC
    Scrape content from a web URL and optionally add it to the knowledge base
    for future RAG queries. The scraper captures both text content and
    screenshots for comprehensive analysis.
    
    Examples:
      ai3 scrape "https://example.com"
      ai3 scrape "https://news.example.com/article"
  LONGDESC
  def scrape(url)
    return say("❌ Please provide a URL to scrape", :red) if url.nil? || url.strip.empty?
    
    validate_url(url)
    
    # Initialize scraper if not already done
    scraper = initialize_scraper
    
    spinner = TTY::Spinner.new("[:spinner] #{I18n.t("ai3.scraper.scraping", url: url)}...", format: :dots)
    spinner.auto_spin
    
    begin
      # Perform scraping
      result = scraper.scrape(url)
      
      spinner.stop
      
      if result[:success]
        say("✅ #{I18n.t("ai3.scraper.content_extracted")}", :green)
        say("📄 Title: #{result[:title]}", :cyan) if result[:title]
        say("📸 Screenshot: #{result[:screenshot]}", :cyan) if result[:screenshot]
        say("🔗 Links found: #{result[:links]&.size || 0}", :cyan) if result[:links]
        
        # Show content preview
        if result[:content] && !result[:content].empty?
          preview = result[:content][0..300]
          preview += "..." if result[:content].length > 300
          say("\n📄 Content Preview:")
          say("#{@pastel.dim(preview)}\n")
        end
        
        # Add to RAG if enabled
        if app_config.dig("rag", "enabled")
          add_scraped_content_to_rag(result)
        end
        
        # Ask if user wants to chat about the content
        if yes?("💬 Would you like to chat about this content?")
          enhanced_query = "Based on the content from #{url}: #{result[:content][0..500]}... Please analyze and summarize this content."
          chat(enhanced_query)
        end
        
      else
        say("❌ #{I18n.t("ai3.scraper.error")}: #{result[:error]}", :red)
      end
      
    rescue StandardError => e
      spinner.stop
      handle_error(e)
    end
  end

  desc "switch PROVIDER", "Switch between LLM providers"
  long_desc <<-LONGDESC
    Switch between different LLM providers. Available providers depend on
    your configuration and API keys.
    
    Common providers: xai, anthropic, openai, ollama
    
    Examples:
      ai3 switch anthropic
      ai3 switch openai
  LONGDESC
  def switch(provider)
    return say("❌ Please specify LLM provider", :red) if provider.nil? || provider.strip.empty?
    
    begin
      llm_manager.switch_provider(provider.to_sym)
      say("✅ Switched to #{provider}", :green)
    rescue StandardError => e
      say("❌ Switch failed: #{e.message}", :red)
    end
  end

  desc "list [TYPE]", "List available assistants, providers, or tools"
  long_desc <<-LONGDESC
    List different types of available resources:
    
    Types:
      assistants - List available AI assistants
      providers  - List LLM providers and their status
      tools      - List available tools and features
    
    Examples:
      ai3 list assistants
      ai3 list providers
      ai3 list tools
  LONGDESC
  def list(type = nil)
    case type&.downcase
    when "assistants", "assistant", "a"
      list_assistants
    when "providers", "provider", "llms", "llm", "l"
      list_llm_providers
    when "tools", "tool", "t"
      list_tools
    else
      say("Available lists: assistants, providers, tools", :yellow)
    end
  end

  desc "status", "Show current system and cognitive status"
  def status
    display_cognitive_status
  end

  desc "config", "Configure AI³ settings and preferences"
  long_desc <<-LONGDESC
    Configure various AI³ settings and preferences. This command provides
    an interactive interface to modify configuration options.
    
    Configuration areas:
      - LLM providers and settings
      - Cognitive framework parameters
      - Session management
      - RAG configuration
      - Security settings
  LONGDESC
  def config
    say("🔧 Configuration management coming soon...", :yellow)
  end

  desc "version", "Show AI³ version information"
  def version
    say("AI³ version #{VERSION}", :cyan)
  end

  # Default task when no arguments provided
  default_task :interactive

  private

  # Load configuration from file
  def load_configuration(config_path)
    if File.exist?(config_path)
      config = YAML.load_file(config_path)
      substitute_env_vars(config)
    else
      say("⚠️ Configuration file not found at #{config_path}, using defaults", :yellow)
      default_configuration
    end
  end

  # Initialize all AI³ components
  def initialize_components
    say("🚀 Initializing AI³ Cognitive Architecture Framework...") if options[:verbose]
    
    # Debug: Check config type
    puts "DEBUG: app_config class: #{app_config.class}" if options[:debug]
    puts "DEBUG: app_config content: #{app_config.inspect}" if options[:debug]
    
    # Initialize cognitive orchestrator (core of 7±2 working memory)
    @cognitive_orchestrator = CognitiveOrchestrator.new
    
    # Initialize multi-LLM manager with fallback chains
    @llm_manager = MultiLLMManager.new(app_config)
    
    # Initialize enhanced session manager with cognitive awareness
    @session_manager = EnhancedSessionManager.new(
      max_sessions: app_config.dig("session", "max_sessions") || 10,
      eviction_strategy: app_config.dig("session", "eviction_strategy")&.to_sym || :cognitive_load_aware
    )
    
    # Initialize RAG engine
    @rag_engine = RAGEngine.new(
      db_path: app_config.dig("rag", "vector_db_path") || "data/vector_store.db"
    )
    @rag_engine.set_cognitive_monitor(cognitive_orchestrator)
    
    # Initialize assistant registry
    @assistant_registry = AssistantRegistry.new(cognitive_orchestrator)
    
    # Set default assistant
    @current_assistant = assistant_registry.get_assistant(
      app_config.dig("assistants", "default_assistant") || "general"
    )
    
    say("✅ AI³ system initialized successfully") if options[:verbose]
  end

  # Setup required directories
  def setup_directories
    directories = %w[data logs tmp config screenshots data/screenshots]
    directories.each do |dir|
      FileUtils.mkdir_p(dir) unless Dir.exist?(dir)
    end
  end

  # Display welcome message
  def display_welcome
    box_content = "#{@pastel.bold.cyan("AI³")} #{@pastel.dim("v" + VERSION)}\n" \
                  "#{I18n.t("ai3.welcome")}\n\n" \
                  "#{@pastel.green("●")} Cognitive Load: #{cognitive_load_indicator}\n" \
                  "#{@pastel.blue("●")} Current Assistant: #{@current_assistant.name}\n" \
                  "#{@pastel.yellow("●")} Current LLM: #{@llm_manager.current_provider}\n\n" \
                  "#{@pastel.dim("Type \"help\" for commands or \"exit\" to quit")}"
    
    puts TTY::Box.frame(box_content, padding: 1, border: :light)
  end

  # Get user input for interactive mode
  def get_user_input
    prompt_text = cognitive_prompt
    
    @prompt.ask(prompt_text) do |q|
      q.required false
      q.modify :strip
    end
  end

  # Generate cognitive-aware prompt
  def cognitive_prompt
    load_indicator = cognitive_load_indicator
    flow_indicator = flow_state_indicator
    
    "#{load_indicator}#{flow_indicator} #{@pastel.cyan("ai3>")} "
  end

  # Process interactive commands
  def process_interactive_command(input)
    parts = input.split(" ", 2)
    command = parts[0].downcase
    args = parts[1]

    case command
    when "chat"
      chat(args)
    when "rag"
      rag(args)
    when "scrape"
      scrape(args)
    when "switch"
      switch(args)
    when "list"
      list(args)
    when "status"
      status
    when "config"
      config
    when "help", "?"
      help
    when "exit", "quit", "q"
      say("👋 #{I18n.t("ai3.messages.goodbye")}")
      exit(0)
    else
      say("❌ #{I18n.t("ai3.errors.command_not_found", command: command)}", :red)
      say("💡 Type 'help' to see available commands", :yellow)
    end
  end

  # Input validation
  def validate_input(input)
    # Basic input sanitization
    if input.length > 10000
      raise ArgumentError, "Input too long (max 10000 characters)"
    end
    
    # Check for potentially malicious content
    dangerous_patterns = [
      /\$\(.*\)/,          # Command substitution
      /`.*`/,              # Backticks
      /<script/i,          # Script tags
      /javascript:/i,      # JavaScript URLs
      /data:.*base64/i     # Data URLs
    ]
    
    dangerous_patterns.each do |pattern|
      if input.match?(pattern)
        raise ArgumentError, "Input contains potentially dangerous content"
      end
    end
  end

  # URL validation
  def validate_url(url)
    require "uri"
    
    begin
      uri = URI.parse(url)
      unless uri.scheme && %w[http https].include?(uri.scheme.downcase)
        raise ArgumentError, "Invalid URL scheme (must be http or https)"
      end
    rescue URI::InvalidURIError
      raise ArgumentError, "Invalid URL format"
    end
  end

  # Initialize scraper
  def initialize_scraper
    scraper_config = {
      screenshot_dir: app_config.dig("scraper", "screenshot_dir") || "data/screenshots",
      max_depth: app_config.dig("scraper", "max_depth") || 2,
      timeout: app_config.dig("scraper", "timeout") || 30,
      user_agent: app_config.dig("scraper", "user_agent") || "AI3-Bot/1.0"
    }
    
    scraper = UniversalScraper.new(scraper_config)
    scraper.set_cognitive_monitor(cognitive_orchestrator)
    scraper
  end

  # Add scraped content to RAG
  def add_scraped_content_to_rag(scrape_result)
    return unless scrape_result[:success] && scrape_result[:content]
    
    document = {
      content: scrape_result[:content],
      title: scrape_result[:title],
      url: scrape_result[:url],
      scraped_at: scrape_result[:timestamp]
    }
    
    collection = "scraped_content"
    
    if rag_engine.add_document(document, collection: collection)
      say("📚 Content added to knowledge base (collection: #{collection})", :green)
    else
      say("⚠️ Failed to add content to knowledge base", :yellow)
    end
  end

  # Display cognitive status
  def display_cognitive_status
    cognitive_state = cognitive_orchestrator.cognitive_state
    session_state = session_manager.cognitive_state
    
    status_content = "#{@pastel.bold("Cognitive Status")}\n\n" \
                     "#{@pastel.yellow("●")} Cognitive Load: #{cognitive_state[:load].round(2)}/7\n" \
                     "#{@pastel.blue("●")} Flow State: #{cognitive_state[:flow_state]}\n" \
                     "#{@pastel.green("●")} Active Concepts: #{cognitive_state[:concepts]}\n" \
                     "#{@pastel.magenta("●")} Context Switches: #{cognitive_state[:switches]}\n" \
                     "#{@pastel.cyan("●")} Overload Risk: #{cognitive_state[:overload_risk]}%\n\n" \
                     "#{@pastel.bold("Session Management")}\n\n" \
                     "#{@pastel.yellow("●")} Active Sessions: #{session_state[:total_sessions]}\n" \
                     "#{@pastel.blue("●")} Cognitive Health: #{session_state[:cognitive_health]}\n" \
                     "#{@pastel.green("●")} Load Distribution: #{session_state[:cognitive_load_percentage]}%"
    
    puts TTY::Box.frame(status_content, padding: 1, border: :light)
  end

  # List assistants
  def list_assistants
    assistants = assistant_registry.list_assistants
    
    say("#{@pastel.bold("Available Assistants:")}\n")
    assistants.each do |assistant|
      status_indicator = assistant[:status][:session_active] ? @pastel.green("●") : @pastel.dim("○")
      current_indicator = assistant[:name] == @current_assistant.name ? @pastel.yellow(" [CURRENT]") : ""
      
      say("#{status_indicator} #{@pastel.cyan(assistant[:name])} - #{assistant[:role]}#{current_indicator}")
      say("  #{@pastel.dim("Capabilities: #{assistant[:capabilities].join(", ")}")}")
      say("  #{@pastel.dim("Cognitive Load: #{assistant[:status][:cognitive_load].round(2)}/7")}\n")
    end
  end

  # List LLM providers
  def list_llm_providers
    status = llm_manager.provider_status
    
    say("#{@pastel.bold("LLM Providers:")}\n")
    status.each do |provider, info|
      status_indicator = info[:available] ? @pastel.green("●") : @pastel.red("●")
      current_indicator = provider == llm_manager.current_provider ? @pastel.yellow(" [CURRENT]") : ""
      
      say("#{status_indicator} #{@pastel.cyan(info[:name])}#{current_indicator}")
      
      if info[:available]
        say("  #{@pastel.dim("Last Success: #{info[:last_success] || "Never"}")}")
      else
        cooldown = info[:cooldown_remaining]
        say("  #{@pastel.red("Cooldown: #{cooldown}s remaining")}") if cooldown > 0
      end
      puts
    end
  end

  # List tools
  def list_tools
    say("🔧 Available tools: RAG, Web Scraping, Session Management, Cognitive Monitoring")
  end

  # Cognitive load indicator
  def cognitive_load_indicator
    load = cognitive_orchestrator.current_load
    
    case load
    when 0..3
      @pastel.green("●")
    when 4..6
      @pastel.yellow("●")
    else
      @pastel.red("●")
    end
  end

  # Flow state indicator
  def flow_state_indicator
    state = cognitive_orchestrator.flow_state_indicators.current_state
    
    case state
    when :optimal
      @pastel.green("◆")
    when :focused
      @pastel.blue("◆")
    when :stressed
      @pastel.yellow("◆")
    else
      @pastel.red("◆")
    end
  end

  # Check cognitive health
  def check_cognitive_health
    if cognitive_orchestrator.cognitive_overload?
      say("⚠️ #{I18n.t("ai3.messages.cognitive_overload")}", :yellow)
      cognitive_orchestrator.trigger_circuit_breaker
    end
  end

  # Handle errors gracefully
  def handle_error(error)
    say("💥 #{@pastel.red("Error:")} #{error.message}", :red)
    say("🔍 #{@pastel.dim("Type \"help\" for usage information")}", :yellow)
    
    # Log error for debugging
    File.open("logs/errors.log", "a") do |f|
      f.puts "[#{Time.now}] #{error.class}: #{error.message}"
      f.puts error.backtrace.join("\n") if error.backtrace
      f.puts "---"
    end
  end

  # Substitute environment variables in config
  def substitute_env_vars(obj)
    case obj
    when Hash
      obj.each { |k, v| obj[k] = substitute_env_vars(v) }
    when Array
      obj.map! { |v| substitute_env_vars(v) }
    when String
      obj.gsub(/\$\{([^}]+)\}/) { |match| ENV[$1] || match }
    else
      obj
    end
  end

  # Default configuration
  def default_configuration
    {
      "llm" => { "primary" => "xai", "fallback_enabled" => true },
      "cognitive" => { "max_working_memory" => 7 },
      "session" => { "max_sessions" => 10 },
      "assistants" => { "default_assistant" => "general" },
      "rag" => { "enabled" => true },
      "scraper" => { "enabled" => true }
    }
  end
end

# Run the CLI if this file is executed directly
if __FILE__ == $0
  AI3CLI.start(ARGV)
end