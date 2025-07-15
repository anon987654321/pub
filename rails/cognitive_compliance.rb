# Rails Cognitive Compliance Module
# Master.json v10.7.0 Implementation
# Implements 7±2 concept chunking, flow state preservation, and cognitive load management

module CognitiveCompliance
  extend ActiveSupport::Concern

  included do
    before_action :initialize_cognitive_monitoring, if: :cognitive_monitoring_enabled?
    after_action :update_cognitive_metrics, if: :cognitive_monitoring_enabled?
    around_action :cognitive_circuit_breaker_protection
  end

  # Cognitive Load Management
  class CognitiveLoadMonitor
    COMPLEXITY_THRESHOLDS = {
      "simple" => 1..2,
      "moderate" => 3..5,
      "complex" => 6..7,
      "overload" => 8..Float::INFINITY
    }.freeze

    CONCEPT_WEIGHTS = {
      "basic_concept" => 1.0,
      "abstract_concept" => 1.5,
      "relationship" => 1.2,
      "nested_structure" => 2.0,
      "cross_domain_reference" => 2.5
    }.freeze

    def initialize
      @current_load = 0
      @concept_stack = []
      @context_switches = 0
      @start_time = Time.now
      @flow_state_tracker = FlowStateTracker.new
    end

    def assess_complexity(content)
      concepts = extract_concepts(content)
      relationships = extract_relationships(content)
      abstractions = assess_abstraction_level(content)

      complexity_score = calculate_weighted_complexity(
        concepts, relationships, abstractions
      )

      {
        "total_complexity" => complexity_score,
        "concept_count" => concepts.length,
        "relationship_count" => relationships.length,
        "abstraction_level" => abstractions,
        "cognitive_load_category" => categorize_load(complexity_score),
        "recommendations" => generate_load_recommendations(complexity_score)
      }
    end

    private

    def extract_concepts(content)
      # Simplified concept extraction for now
      content.to_s.scan(/\b[A-Z][a-z]+\b/).uniq
    end

    def extract_relationships(content)
      # Simplified relationship extraction
      content.to_s.scan(/\b(has|belongs_to|many|one)\b/).uniq
    end

    def assess_abstraction_level(content)
      # Simple abstraction assessment
      abstract_keywords = %w[abstract module interface pattern strategy]
      abstract_keywords.count { |keyword| content.to_s.downcase.include?(keyword) }
    end

    def calculate_weighted_complexity(concepts, relationships, abstractions)
      concept_load = concepts.sum { |concept| 
        CONCEPT_WEIGHTS["basic_concept"] || 1.0 
      }
      
      relationship_load = relationships.length * CONCEPT_WEIGHTS["relationship"]
      abstraction_load = abstractions * CONCEPT_WEIGHTS["abstract_concept"]
      
      base_load = concept_load + relationship_load + abstraction_load
      
      # Miller's Law: effectiveness decreases exponentially after 7±2 items
      if base_load > 7
        penalty = Math.exp((base_load - 7) * 0.2)
        base_load * penalty
      else
        base_load
      end
    end

    def categorize_load(score)
      COMPLEXITY_THRESHOLDS.find { |category, range| range.include?(score) }&.first || "overload"
    end

    def generate_load_recommendations(score)
      case categorize_load(score)
      when "overload"
        ["Break down into smaller components", "Implement progressive disclosure", "Add cognitive breaks"]
      when "complex"
        ["Review for simplification opportunities", "Add explanatory comments", "Consider chunking"]
      when "moderate"
        ["Good complexity level", "Monitor for increases"]
      else
        ["Optimal cognitive load"]
      end
    end
  end

  # Flow State Tracking
  class FlowStateTracker
    FLOW_INDICATORS = {
      "concentration" => { "weight" => 0.25, "threshold" => 0.7 },
      "challenge_skill_balance" => { "weight" => 0.20, "threshold" => 0.6 },
      "clear_goals" => { "weight" => 0.15, "threshold" => 0.8 },
      "immediate_feedback" => { "weight" => 0.15, "threshold" => 0.7 },
      "sense_of_control" => { "weight" => 0.10, "threshold" => 0.6 },
      "loss_of_self_consciousness" => { "weight" => 0.10, "threshold" => 0.5 },
      "time_transformation" => { "weight" => 0.05, "threshold" => 0.4 }
    }.freeze

    def initialize
      @indicators = {}
      @flow_history = []
      @interruption_count = 0
      @flow_session_start = nil
    end

    def update(metrics)
      previous_flow_state = current_flow_level
      
      # Update individual indicators
      FLOW_INDICATORS.each do |indicator, config|
        if metrics.key?(indicator)
          @indicators[indicator] = metrics[indicator].to_f
        end
      end
      
      current_flow_state = current_flow_level
      
      # Detect flow state transitions
      if entering_flow_state?(previous_flow_state, current_flow_state)
        @flow_session_start = Time.now
      elsif exiting_flow_state?(previous_flow_state, current_flow_state)
        @flow_session_start = nil
      end
      
      # Record flow history
      @flow_history << {
        "timestamp" => Time.now,
        "flow_level" => current_flow_state,
        "indicators" => @indicators.dup
      }
      
      # Maintain history limit (7±2 concept)
      @flow_history = @flow_history.last(7)
      
      current_flow_state
    end

    def current_flow_level
      total_score = 0.0
      total_weight = 0.0
      
      FLOW_INDICATORS.each do |indicator, config|
        indicator_value = @indicators[indicator] || 0.0
        weight = config["weight"]
        threshold = config["threshold"]
        
        # Apply threshold scaling
        scaled_value = if indicator_value >= threshold
          indicator_value
        else
          indicator_value * (indicator_value / threshold)
        end
        
        total_score += scaled_value * weight
        total_weight += weight
      end
      
      total_score / total_weight
    end

    def in_flow_state?
      current_flow_level >= 0.7
    end

    def distraction_level
      1.0 - current_flow_level
    end

    private

    def entering_flow_state?(previous, current)
      previous < 0.7 && current >= 0.7
    end

    def exiting_flow_state?(previous, current)
      previous >= 0.7 && current < 0.7
    end
  end

  # Circuit Breaker for Cognitive Protection
  class CognitiveCircuitBreaker
    FAILURE_THRESHOLD = 3
    TIMEOUT_DURATION = 300 # 5 minutes
    HALF_OPEN_RETRY_LIMIT = 1

    def initialize(name)
      @name = name
      @state = :closed # :closed, :open, :half_open
      @failure_count = 0
      @last_failure_time = nil
      @success_count = 0
    end

    def call(cognitive_load_data)
      case @state
      when :closed
        execute_with_monitoring(cognitive_load_data) { yield }
      when :open
        if timeout_expired?
          transition_to_half_open
          execute_with_monitoring(cognitive_load_data) { yield }
        else
          raise CognitiveOverloadError, "Circuit breaker is OPEN. System in cognitive protection mode."
        end
      when :half_open
        if @success_count >= HALF_OPEN_RETRY_LIMIT
          transition_to_closed
        end
        execute_with_monitoring(cognitive_load_data) { yield }
      end
    end

    private

    def execute_with_monitoring(cognitive_load_data)
      if cognitive_overload_detected?(cognitive_load_data)
        record_failure("Cognitive overload detected")
        raise CognitiveOverloadError, "Pre-execution cognitive overload detected"
      end

      begin
        result = yield
        record_success
        result
      rescue => e
        record_failure("Exception during execution: #{e.message}")
        raise
      end
    end

    def cognitive_overload_detected?(data)
      (data["cognitive_load"] || 0) > 7 ||
      (data["context_switches"] || 0) > 3 ||
      (data["error_count"] || 0) > 5
    end

    def record_failure(reason)
      @failure_count += 1
      @last_failure_time = Time.now
      @success_count = 0
      
      if @failure_count >= FAILURE_THRESHOLD
        transition_to_open
      end
    end

    def record_success
      @success_count += 1
      
      if @state == :half_open && @success_count >= HALF_OPEN_RETRY_LIMIT
        transition_to_closed
      elsif @state == :closed
        @failure_count = [@failure_count - 0.5, 0].max
      end
    end

    def transition_to_open
      @state = :open
      @last_failure_time = Time.now
    end

    def transition_to_half_open
      @state = :half_open
      @success_count = 0
    end

    def transition_to_closed
      @state = :closed
      @failure_count = 0
      @success_count = 0
      @last_failure_time = nil
    end

    def timeout_expired?
      return false unless @last_failure_time
      Time.now - @last_failure_time >= TIMEOUT_DURATION
    end
  end

  # Custom exception for cognitive overload
  class CognitiveOverloadError < StandardError; end

  # Controller methods
  def initialize_cognitive_monitoring
    @cognitive_session = {
      "user" => current_user,
      "context" => cognitive_context,
      "session_id" => session.id,
      "start_time" => Time.now,
      "current_load" => 0
    }
  end

  def update_cognitive_metrics
    request_complexity = analyze_request_complexity
    response_complexity = analyze_response_complexity
    
    @cognitive_session["request_complexity"] = request_complexity
    @cognitive_session["response_complexity"] = response_complexity
    @cognitive_session["current_load"] = request_complexity + response_complexity
    
    # Check for cognitive overload
    if @cognitive_session["current_load"] > 7
      suggest_cognitive_break
    end
  end

  def cognitive_circuit_breaker_protection
    circuit_breaker = CognitiveCircuitBreaker.new("#{controller_name}_#{action_name}")
    
    cognitive_load_data = {
      "current_load" => @cognitive_session&.dig("current_load") || 0,
      "context_switches" => session["context_switches"] || 0,
      "error_count" => session["error_count"] || 0
    }
    
    circuit_breaker.call(cognitive_load_data) do
      yield
    end
  rescue CognitiveOverloadError => e
    handle_cognitive_overload(e)
  end

  private

  def cognitive_monitoring_enabled?
    Rails.env.production? || ENV["COGNITIVE_MONITORING"] == "true"
  end

  def cognitive_context
    {
      "controller" => controller_name,
      "action" => action_name,
      "request_method" => request.method,
      "user_agent" => request.user_agent
    }
  end

  def analyze_request_complexity
    complexity_factors = {
      "parameter_count" => params.keys.length,
      "nested_parameters" => count_nested_parameters(params),
      "request_size" => request.content_length || 0
    }
    
    complexity_factors.values.sum / 1000.0 # Normalize
  end

  def analyze_response_complexity
    # Simplified response complexity analysis
    response_factors = {
      "status_code" => response.status,
      "headers_count" => response.headers.keys.length,
      "content_type" => response.content_type&.include?("html") ? 2 : 1
    }
    
    response_factors.values.sum / 100.0 # Normalize
  end

  def count_nested_parameters(params_hash)
    params_hash.values.count { |value| value.is_a?(Hash) || value.is_a?(Array) }
  end

  def suggest_cognitive_break
    @cognitive_overload_detected = true
    @break_suggestion = {
      "type" => "micro_break",
      "duration" => 3,
      "activity" => "Take 3 deep breaths and focus on the present moment"
    }
  end

  def handle_cognitive_overload(error)
    @cognitive_overload_detected = true
    @simplified_response = true
    
    render "shared/cognitive_overload", status: 503
  end
end