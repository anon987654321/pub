# frozen_string_literal: true

require_relative 'multi_llm_manager'
require_relative 'assistant_registry'
require_relative 'query_cache'
require 'json'
require 'logger'
require 'digest'

# Enhanced Assistant Orchestrator with unified request processing
# Integrates multi-assistant coordination and specialized agent swarms
class EnhancedAssistantOrchestrator
  attr_reader :llm_manager, :registry, :active_assistants, :cache, :logger, :swarm_agents

  def initialize(config = {})
    @config = config
    @llm_manager = MultiLLMManager.new(config[:llm] || {})
    @registry = AssistantRegistry.new
    @active_assistants = {}
    @cache = QueryCache.new(ttl: 1800, max_size: 200)
    @logger = Logger.new(STDOUT)
    @logger.level = Logger::INFO
    @swarm_agents = initialize_swarm_agents
    @logger.info("Enhanced AssistantOrchestrator initialized with #{@swarm_agents.size} swarm agents")
  end

  # Get or create assistant with enhanced capabilities
  def get_or_create_assistant(type:, user_id:, specialized: false)
    key = "#{type}_#{user_id}"
    
    @active_assistants[key] ||= begin
      if specialized && @swarm_agents.key?(type)
        create_specialized_assistant(type, user_id)
      else
        @registry.create_assistant(type, @llm_manager)
      end
    end
  end

  # Enhanced request routing with caching and swarm coordination
  def route_request(request)
    cache_key = generate_cache_key(request)
    
    # Check cache first
    cached_response = @cache.retrieve(cache_key)
    if cached_response
      @logger.info("Cache hit for request: #{request[:query]&.to_s&.slice(0, 50) || 'unknown'}")
      return enhance_cached_response(cached_response, request)
    end

    # Route to appropriate assistant or swarm
    response = if request[:requires_swarm]
      coordinate_swarm_response(request)
    else
      process_single_assistant(request)
    end

    # Cache successful responses
    @cache.add(cache_key, response) if response[:success]
    
    response
  end

  # Coordinate multiple agents for complex tasks
  def coordinate_swarm_response(request)
    relevant_agents = determine_relevant_agents(request)
    @logger.info("Coordinating #{relevant_agents.size} agents for swarm response")

    responses = relevant_agents.map do |agent_type|
      agent = @swarm_agents[agent_type]
      begin
        agent_response = agent.respond_to?(:process) ? agent.process(request) : { message: "Agent #{agent_type} processed request" }
        { agent: agent_type, response: agent_response, success: true }
      rescue StandardError => e
        @logger.error("Agent #{agent_type} failed: #{e.message}")
        { agent: agent_type, error: e.message, success: false }
      end
    end

    synthesize_swarm_responses(responses, request)
  end

  # Music swarm specialized coordination (10-agent system)
  def coordinate_music_swarm(request)
    music_agents = %i[
      genre_specialist rhythm_analyst melody_composer
      lyrics_generator harmony_architect production_expert
      mastering_specialist trend_analyzer collaborative_mixer
      performance_optimizer
    ]

    return { error: 'Music swarm not available', success: false } unless music_swarm_available?

    @logger.info("Activating 10-agent music swarm for request: #{request[:type]}")
    
    # Sequential processing with each agent building on previous work
    accumulated_context = request.dup
    results = {}

    music_agents.each do |agent_type|
      agent = @swarm_agents[agent_type]
      next unless agent

      begin
        agent_result = agent.respond_to?(:process) ? agent.process(accumulated_context) : create_mock_music_result(agent_type)
        results[agent_type] = agent_result
        accumulated_context[:context] = (accumulated_context[:context] || {}).merge(agent_result)
        @logger.debug("Agent #{agent_type} completed processing")
      rescue StandardError => e
        @logger.error("Music agent #{agent_type} failed: #{e.message}")
        results[agent_type] = { error: e.message }
      end
    end

    {
      swarm_type: 'music',
      agents_used: music_agents,
      results: results,
      final_composition: synthesize_music_results(results),
      success: true
    }
  end

  # Enhanced processing for Amber fashion network integration
  def coordinate_fashion_swarm(request)
    fashion_agents = %i[
      wardrobe_analyzer style_consultant outfit_generator
      trend_predictor color_specialist brand_matcher
    ]

    @logger.info("Activating fashion AI swarm for Amber network request")
    
    results = {}
    fashion_agents.each do |agent_type|
      agent = @swarm_agents[agent_type] || create_fashion_agent(agent_type)
      results[agent_type] = agent.respond_to?(:process) ? agent.process(request) : create_mock_fashion_result(agent_type, request)
    end

    {
      swarm_type: 'fashion',
      agents_used: fashion_agents,
      results: results,
      fashion_recommendation: synthesize_fashion_results(results),
      success: true
    }
  end

  private

  def initialize_swarm_agents
    agents = {}
    
    # Music swarm agents with genre specialization
    %i[
      genre_specialist rhythm_analyst melody_composer lyrics_generator
      harmony_architect production_expert mastering_specialist trend_analyzer
      collaborative_mixer performance_optimizer
    ].each do |agent_type|
      agents[agent_type] = create_swarm_agent(agent_type)
    end

    # Fashion network agents for Amber integration
    %i[wardrobe_analyzer style_consultant outfit_generator trend_predictor color_specialist brand_matcher].each do |agent_type|
      agents[agent_type] = create_swarm_agent(agent_type)
    end

    # General specialized agents
    %i[business_analyst technical_writer code_reviewer security_auditor].each do |agent_type|
      agents[agent_type] = create_swarm_agent(agent_type)
    end

    agents
  end

  def create_swarm_agent(type)
    # Create specialized agent with specific capabilities
    agent_config = {
      type: type,
      llm_manager: @llm_manager,
      specialization: get_agent_specialization(type)
    }
    
    # Return a basic agent structure for now
    {
      type: type,
      config: agent_config,
      process: lambda do |request|
        create_agent_response(type, request)
      end
    }
  end

  def create_agent_response(agent_type, request)
    case agent_type
    when :genre_specialist
      { genre_recommendation: "Electronic/Ambient", confidence: 0.85, reasoning: "Based on current trends and user preferences" }
    when :rhythm_analyst
      { rhythm_pattern: "4/4 with syncopated elements", bpm: 128, complexity: "medium" }
    when :wardrobe_analyzer
      { wardrobe_efficiency: 0.75, underutilized_items: 12, cost_per_wear_analysis: "completed" }
    when :style_consultant
      { style_profile: "Modern minimalist", color_palette: ["navy", "white", "beige"], seasonal_adjustments: "spring_ready" }
    else
      { agent: agent_type, processed: true, timestamp: Time.now }
    end
  end

  def process_single_assistant(request)
    assistant = get_or_create_assistant(
      type: request[:assistant_type] || :general,
      user_id: request[:user_id],
      specialized: request[:specialized] || false
    )
    
    begin
      response = assistant.respond_to?(:process) ? assistant.process(request) : { message: "Request processed", success: true }
      { response: response, success: true, assistant_type: request[:assistant_type] }
    rescue StandardError => e
      @logger.error("Assistant processing failed: #{e.message}")
      { error: e.message, success: false }
    end
  end

  def generate_cache_key(request)
    key_components = [
      request[:query]&.to_s&.strip,
      request[:assistant_type],
      request[:user_id],
      request[:context]&.to_s&.hash
    ].compact

    Digest::SHA256.hexdigest(key_components.join('|'))[0..15]
  end

  def determine_relevant_agents(request)
    case request[:domain]&.to_s
    when 'music', 'audio', 'composition'
      %i[genre_specialist rhythm_analyst melody_composer production_expert]
    when 'fashion', 'style', 'wardrobe'
      %i[wardrobe_analyzer style_consultant outfit_generator trend_predictor]
    when 'business', 'strategy'
      %i[business_analyst trend_analyzer]
    when 'technical', 'code', 'development'
      %i[technical_writer code_reviewer security_auditor]
    else
      %i[genre_specialist business_analyst technical_writer]
    end
  end

  def synthesize_swarm_responses(responses, request)
    successful_responses = responses.select { |r| r[:success] }
    
    return { error: 'All agents failed', success: false } if successful_responses.empty?

    # Combine successful responses intelligently
    {
      swarm_coordination: true,
      agents_used: successful_responses.map { |r| r[:agent] },
      individual_responses: successful_responses,
      synthesized_result: generate_synthesis(successful_responses, request),
      success: true
    }
  end

  def synthesize_music_results(results)
    # Combine music agent results into coherent composition
    {
      genre: results[:genre_specialist]&.dig(:genre_recommendation),
      rhythm: results[:rhythm_analyst]&.dig(:rhythm_pattern),
      melody: results[:melody_composer]&.dig(:melody_structure),
      lyrics: results[:lyrics_generator]&.dig(:lyric_content),
      harmony: results[:harmony_architect]&.dig(:harmonic_progression),
      production: results[:production_expert]&.dig(:production_notes),
      mastering: results[:mastering_specialist]&.dig(:mastering_chain),
      trends: results[:trend_analyzer]&.dig(:trend_alignment),
      mix: results[:collaborative_mixer]&.dig(:mix_elements),
      performance: results[:performance_optimizer]&.dig(:performance_tips)
    }
  end

  def synthesize_fashion_results(results)
    # Combine fashion agent results for Amber network
    {
      wardrobe_analysis: results[:wardrobe_analyzer],
      style_recommendation: results[:style_consultant],
      outfit_suggestions: results[:outfit_generator],
      trend_insights: results[:trend_predictor],
      color_coordination: results[:color_specialist],
      brand_matches: results[:brand_matcher]
    }
  end

  def generate_synthesis(responses, request)
    # Simple synthesis for now - could be enhanced with LLM-based synthesis
    responses.map { |r| r[:response] }.join("\n\n---\n\n")
  end

  def enhance_cached_response(cached_response, request)
    # Add fresh context or user-specific enhancements to cached response
    cached_response.merge({
      cached: true,
      cache_timestamp: Time.now,
      user_context: request[:user_id]
    })
  end

  def get_agent_specialization(type)
    specializations = {
      genre_specialist: "Expert in music genre classification and characteristics",
      rhythm_analyst: "Specialist in rhythm patterns and beat structures", 
      melody_composer: "Creative melody composition and harmonic progression",
      lyrics_generator: "Lyrical content creation and storytelling",
      harmony_architect: "Complex harmonic structures and chord progressions",
      production_expert: "Audio production techniques and sound design",
      mastering_specialist: "Audio mastering and final production polish",
      trend_analyzer: "Current music trends and market analysis",
      collaborative_mixer: "Multi-track mixing and arrangement",
      performance_optimizer: "Live performance optimization and staging",
      wardrobe_analyzer: "AI-powered wardrobe management and analytics",
      style_consultant: "Personal style analysis and recommendations",
      outfit_generator: "Daily outfit suggestions and coordination",
      trend_predictor: "Fashion trend analysis and prediction",
      color_specialist: "Color theory and coordination expertise",
      brand_matcher: "Brand analysis and product matching",
      business_analyst: "Business strategy and market analysis",
      technical_writer: "Technical documentation and code explanation",
      code_reviewer: "Code quality assessment and security review",
      security_auditor: "Security vulnerability assessment"
    }

    specializations[type] || "General purpose assistant"
  end

  def music_swarm_available?
    required_agents = %i[genre_specialist rhythm_analyst melody_composer production_expert]
    required_agents.all? { |agent| @swarm_agents.key?(agent) }
  end

  def create_fashion_agent(type)
    create_swarm_agent(type)
  end

  def create_mock_music_result(agent_type)
    case agent_type
    when :genre_specialist
      { genre_recommendation: "Synthwave", subgenres: ["Retrowave", "Darksynth"], confidence: 0.92 }
    when :rhythm_analyst
      { rhythm_pattern: "4/4 with 16th note hi-hats", groove: "driving", swing: "minimal" }
    when :melody_composer
      { melody_structure: "ABABCB", key: "C minor", scale: "natural minor", intervals: ["4th", "5th", "octave"] }
    else
      { agent: agent_type, result: "processed", quality: "high" }
    end
  end

  def create_mock_fashion_result(agent_type, request)
    case agent_type
    when :wardrobe_analyzer
      { items_analyzed: 47, cost_per_wear: 12.50, underutilized_count: 8, efficiency_score: 0.73 }
    when :style_consultant
      { style_profile: "Contemporary minimalist", confidence: 0.88, seasonal_palette: ["sage", "cream", "charcoal"] }
    when :outfit_generator
      { daily_suggestions: 3, coordination_score: 0.91, weather_appropriate: true }
    else
      { agent: agent_type, recommendation: "optimized", confidence: 0.85 }
    end
  end
end