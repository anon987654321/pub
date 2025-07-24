# frozen_string_literal: true

# Business Planning Service for Rails Application
# Integrates lean canvas, OKR tracking, and strategic planning tools
class BusinessPlanningService
  include CableReady::Broadcaster
  
  attr_reader :user, :community, :current_plan
  
  def initialize(user: nil, community: nil)
    @user = user
    @community = community
    @logger = Rails.logger
    setup_planning_components
  end
  
  # Lean Canvas Management
  def create_lean_canvas(params = {})
    canvas_data = {
      id: generate_canvas_id,
      problem: params[:problem] || [],
      solution: params[:solution] || [],
      unique_value_proposition: params[:uvp] || "",
      unfair_advantage: params[:unfair_advantage] || "",
      customer_segments: params[:customer_segments] || [],
      key_metrics: params[:key_metrics] || [],
      channels: params[:channels] || [],
      cost_structure: params[:cost_structure] || [],
      revenue_streams: params[:revenue_streams] || [],
      created_at: Time.current.iso8601,
      created_by: @user&.id,
      community_id: @community&.id
    }
    
    store_business_plan("lean_canvas", canvas_data)
    broadcast_canvas_update(canvas_data) if @user
    
    success_response(canvas_data)
  rescue StandardError => e
    error_response("Failed to create lean canvas: #{e.message}")
  end
  
  # Update existing lean canvas
  def update_lean_canvas(canvas_id, updates = {})
    existing_canvas = get_business_plan("lean_canvas", canvas_id)
    return error_response("Canvas not found") unless existing_canvas
    
    updated_canvas = existing_canvas.merge(updates).merge(
      updated_at: Time.current.iso8601,
      updated_by: @user&.id
    )
    
    store_business_plan("lean_canvas", updated_canvas, canvas_id)
    broadcast_canvas_update(updated_canvas) if @user
    
    success_response(updated_canvas)
  rescue StandardError => e
    error_response("Failed to update lean canvas: #{e.message}")
  end
  
  # OKR (Objectives and Key Results) Management
  def create_okr(objective, key_results = [])
    okr_data = {
      id: generate_okr_id,
      objective: objective,
      key_results: key_results.map.with_index { |kr, idx| 
        {
          id: idx + 1,
          description: kr[:description] || kr,
          target_value: kr[:target_value] || 100,
          current_value: kr[:current_value] || 0,
          unit: kr[:unit] || "percentage",
          progress: calculate_progress(kr[:current_value] || 0, kr[:target_value] || 100)
        }
      },
      quarter: current_quarter,
      year: Date.current.year,
      status: "draft",
      created_at: Time.current.iso8601,
      created_by: @user&.id,
      community_id: @community&.id
    }
    
    store_business_plan("okr", okr_data)
    success_response(okr_data)
  rescue StandardError => e
    error_response("Failed to create OKR: #{e.message}")
  end
  
  # Update OKR progress
  def update_okr_progress(okr_id, key_result_id, new_value)
    okr = get_business_plan("okr", okr_id)
    return error_response("OKR not found") unless okr
    
    key_result = okr[:key_results].find { |kr| kr[:id] == key_result_id.to_i }
    return error_response("Key result not found") unless key_result
    
    key_result[:current_value] = new_value.to_f
    key_result[:progress] = calculate_progress(key_result[:current_value], key_result[:target_value])
    key_result[:updated_at] = Time.current.iso8601
    
    # Update overall OKR status based on progress
    okr[:status] = determine_okr_status(okr[:key_results])
    okr[:updated_at] = Time.current.iso8601
    
    store_business_plan("okr", okr, okr_id)
    broadcast_okr_update(okr) if @user
    
    success_response(okr)
  rescue StandardError => e
    error_response("Failed to update OKR progress: #{e.message}")
  end
  
  # Stakeholder Mapping
  def create_stakeholder_map(stakeholders = [])
    stakeholder_map = {
      id: generate_map_id,
      stakeholders: stakeholders.map.with_index { |stakeholder, idx|
        {
          id: idx + 1,
          name: stakeholder[:name],
          role: stakeholder[:role] || "Unknown",
          influence: stakeholder[:influence] || "medium", # low, medium, high
          interest: stakeholder[:interest] || "medium",   # low, medium, high
          engagement_strategy: stakeholder[:engagement_strategy] || "",
          contact_info: stakeholder[:contact_info] || {},
          notes: stakeholder[:notes] || ""
        }
      },
      created_at: Time.current.iso8601,
      created_by: @user&.id,
      community_id: @community&.id
    }
    
    store_business_plan("stakeholder_map", stakeholder_map)
    success_response(stakeholder_map)
  end
  
  # Design Thinking Workflow
  def initiate_design_thinking_session(challenge_statement)
    session_data = {
      id: generate_session_id,
      challenge_statement: challenge_statement,
      phases: {
        empathize: { status: "active", insights: [], user_personas: [] },
        define: { status: "pending", problem_statement: "", how_might_we: [] },
        ideate: { status: "pending", ideas: [], selected_concepts: [] },
        prototype: { status: "pending", prototypes: [], feedback: [] },
        test: { status: "pending", tests: [], learnings: [], iterations: [] }
      },
      current_phase: "empathize",
      participants: [@user&.id].compact,
      created_at: Time.current.iso8601,
      community_id: @community&.id
    }
    
    store_business_plan("design_thinking", session_data)
    success_response(session_data)
  end
  
  # Update design thinking phase
  def update_design_thinking_phase(session_id, phase, updates = {})
    session = get_business_plan("design_thinking", session_id)
    return error_response("Session not found") unless session
    
    return error_response("Invalid phase") unless session[:phases].key?(phase.to_sym)
    
    session[:phases][phase.to_sym].merge!(updates)
    session[:phases][phase.to_sym][:updated_at] = Time.current.iso8601
    session[:updated_at] = Time.current.iso8601
    
    store_business_plan("design_thinking", session, session_id)
    success_response(session)
  end
  
  # Get all business plans for user/community
  def get_all_plans(plan_type = nil)
    plans = {}
    
    plan_types = plan_type ? [plan_type] : %w[lean_canvas okr stakeholder_map design_thinking]
    
    plan_types.each do |type|
      plans[type] = get_plans_by_type(type)
    end
    
    success_response(plans)
  rescue StandardError => e
    error_response("Failed to retrieve plans: #{e.message}")
  end
  
  # Analytics and Insights
  def generate_business_insights
    insights = {
      lean_canvas_completion: calculate_canvas_completion,
      okr_performance: calculate_okr_performance,
      stakeholder_engagement: analyze_stakeholder_engagement,
      design_thinking_progress: analyze_design_thinking_progress,
      recommendations: generate_recommendations,
      generated_at: Time.current.iso8601
    }
    
    success_response(insights)
  rescue StandardError => e
    error_response("Failed to generate insights: #{e.message}")
  end
  
  # Integration with Norwegian Hedge Fund trading algorithms
  def integrate_trading_strategies(strategy_params = {})
    return error_response("Trading integration not available") unless trading_integration_available?
    
    # Load trading strategy from bplans/norwegianhedge
    strategy_result = execute_trading_strategy(strategy_params)
    
    # Store as business plan component
    trading_plan = {
      id: generate_trading_id,
      strategy_type: strategy_params[:strategy_type] || "swarm_trading",
      parameters: strategy_params,
      results: strategy_result,
      created_at: Time.current.iso8601,
      community_id: @community&.id
    }
    
    store_business_plan("trading_strategy", trading_plan)
    success_response(trading_plan)
  rescue StandardError => e
    error_response("Trading integration failed: #{e.message}")
  end
  
  private
  
  def setup_planning_components
    @plans_storage = initialize_storage
    @trading_available = check_trading_availability
  end
  
  def initialize_storage
    # Use Redis for fast access or database for persistence
    if Rails.cache.respond_to?(:redis)
      Rails.cache
    else
      {} # Fallback to memory storage
    end
  end
  
  def store_business_plan(type, data, id = nil)
    plan_id = id || data[:id]
    cache_key = business_plan_cache_key(type, plan_id)
    
    if @plans_storage.respond_to?(:write)
      @plans_storage.write(cache_key, data.to_json, expires_in: 30.days)
    else
      @plans_storage[cache_key] = data
    end
  end
  
  def get_business_plan(type, id)
    cache_key = business_plan_cache_key(type, id)
    
    if @plans_storage.respond_to?(:read)
      cached_data = @plans_storage.read(cache_key)
      cached_data ? JSON.parse(cached_data, symbolize_names: true) : nil
    else
      @plans_storage[cache_key]
    end
  end
  
  def get_plans_by_type(type)
    # This would typically query a database in production
    # For now, return cached plans
    pattern = business_plan_cache_key(type, "*")
    
    if @plans_storage.respond_to?(:delete_matched)
      # Redis-like interface
      keys = @plans_storage.instance_variable_get(:@data)&.keys&.select { |k| k.match?(Regexp.new(pattern.gsub("*", ".*"))) } || []
      keys.map { |key| get_business_plan(type, key.split(":").last) }.compact
    else
      @plans_storage.select { |k, _v| k.include?(type) }.values
    end
  end
  
  def business_plan_cache_key(type, id)
    "business_plans:#{@community&.id || 'global'}:#{type}:#{id}"
  end
  
  def generate_canvas_id
    "canvas_#{SecureRandom.hex(8)}"
  end
  
  def generate_okr_id
    "okr_#{SecureRandom.hex(8)}"
  end
  
  def generate_map_id
    "map_#{SecureRandom.hex(8)}"
  end
  
  def generate_session_id
    "dt_#{SecureRandom.hex(8)}"
  end
  
  def generate_trading_id
    "trade_#{SecureRandom.hex(8)}"
  end
  
  def current_quarter
    "Q#{((Date.current.month - 1) / 3) + 1}"
  end
  
  def calculate_progress(current, target)
    return 0.0 if target.zero?
    ((current.to_f / target.to_f) * 100).round(2)
  end
  
  def determine_okr_status(key_results)
    avg_progress = key_results.sum { |kr| kr[:progress] } / key_results.length.to_f
    
    case avg_progress
    when 0..25 then "at_risk"
    when 26..70 then "on_track"
    when 71..90 then "ahead"
    else "completed"
    end
  end
  
  def calculate_canvas_completion
    # Calculate completion percentage of lean canvas sections
    # This would analyze actual canvas data
    85.0 # Placeholder
  end
  
  def calculate_okr_performance
    # Analyze OKR performance across quarters
    {
      current_quarter_avg: 78.5,
      on_track_count: 8,
      at_risk_count: 2,
      completed_count: 12
    }
  end
  
  def analyze_stakeholder_engagement
    {
      high_influence_engaged: 85.0,
      key_stakeholders_contacted: 92.0,
      engagement_score: 78.5
    }
  end
  
  def analyze_design_thinking_progress
    {
      sessions_completed: 3,
      avg_session_duration: "2.5 hours",
      ideas_generated: 47,
      prototypes_created: 8
    }
  end
  
  def generate_recommendations
    [
      "Focus on high-influence stakeholders for better project outcomes",
      "Consider updating OKRs that are consistently behind target",
      "Your lean canvas problem-solution fit shows strong alignment",
      "Design thinking sessions are generating high-quality insights"
    ]
  end
  
  def broadcast_canvas_update(canvas_data)
    cable_ready
      .replace(
        selector: "#lean-canvas-#{canvas_data[:id]}",
        html: render_canvas_html(canvas_data)
      )
      .broadcast_to(@user, identifier: "BusinessPlanningChannel")
  end
  
  def broadcast_okr_update(okr_data)
    cable_ready
      .replace(
        selector: "#okr-#{okr_data[:id]}",
        html: render_okr_html(okr_data)
      )
      .broadcast_to(@user, identifier: "BusinessPlanningChannel")
  end
  
  def render_canvas_html(canvas_data)
    # Simple HTML rendering - would use proper view templates in production
    "<div class='canvas-summary'>Canvas updated: #{canvas_data[:unique_value_proposition]}</div>"
  end
  
  def render_okr_html(okr_data)
    progress = okr_data[:key_results].sum { |kr| kr[:progress] } / okr_data[:key_results].length
    "<div class='okr-summary'>OKR: #{okr_data[:objective]} (#{progress.round(1)}% complete)</div>"
  end
  
  def check_trading_availability
    bplans_path = Rails.root.join('lib', 'integrations', 'bplans')
    bplans_path.exist? && bplans_path.join('norwegianhedge').exist?
  end
  
  def trading_integration_available?
    @trading_available
  end
  
  def execute_trading_strategy(params)
    # This would integrate with the Norwegian hedge fund trading system
    # For now, return simulated results
    {
      strategy: params[:strategy_type],
      executed_at: Time.current.iso8601,
      simulated_return: rand(1.0..15.0).round(2),
      risk_score: rand(1..10),
      recommendation: "Hold position with 15% portfolio allocation"
    }
  end
  
  def success_response(data)
    {
      success: true,
      data: data,
      timestamp: Time.current.iso8601
    }
  end
  
  def error_response(message)
    {
      success: false,
      error: message,
      timestamp: Time.current.iso8601
    }
  end
end