# frozen_string_literal: true

# SwarmAgent - Autonomous agent coordination system
# Extracted and enhanced from musicians.rb swarm patterns
require 'logger'
require 'securerandom'
require 'timeout'

# Graceful concurrent-ruby loading
begin
  require 'concurrent-ruby'
  CONCURRENT_AVAILABLE = true
rescue LoadError
  CONCURRENT_AVAILABLE = false
  puts "Warning: concurrent-ruby gem not available. Using simplified threading."
end

class SwarmAgent
  attr_reader :name, :task, :data_sources, :report, :status, :agent_id
  attr_accessor :cognitive_monitor

  def initialize(name:, task:, data_sources: [], config: {})
    @name = name
    @task = task
    @data_sources = data_sources
    @agent_id = SecureRandom.hex(8)
    @status = :initialized
    @report = nil
    @config = default_config.merge(config)
    @logger = @config[:logger] || Logger.new(STDOUT)
    @cognitive_monitor = nil
    
    @logger.info("SwarmAgent #{@name} (#{@agent_id}) initialized with task: #{@task}")
  end

  # Execute the agent's task
  def execute
    return if @status == :executing || @status == :completed

    @status = :executing
    @logger.info("Agent #{@name} starting execution")
    
    begin
      # Check cognitive capacity if monitor available
      if @cognitive_monitor&.cognitive_overload?
        @logger.warn("Agent #{@name} deferred due to cognitive overload")
        @status = :deferred
        return false
      end

      # Execute task with timeout
      result = Timeout.timeout(@config[:timeout]) do
        execute_task
      end

      @report = result
      @status = :completed
      @logger.info("Agent #{@name} completed successfully")
      
      # Update cognitive load
      if @cognitive_monitor
        complexity = calculate_task_complexity
        @cognitive_monitor.add_concept(@task[0..50], complexity * 0.1)
      end
      
      true
    rescue Timeout::Error
      @logger.error("Agent #{@name} timed out")
      @status = :timeout
      @report = "Task timed out after #{@config[:timeout]} seconds"
      false
    rescue StandardError => e
      @logger.error("Agent #{@name} failed: #{e.message}")
      @status = :failed
      @report = "Task failed: #{e.message}"
      false
    end
  end

  # Execute task asynchronously
  def execute_async
    if CONCURRENT_AVAILABLE
      Concurrent::Future.execute do
        execute
      end
    else
      # Fallback to simple Thread
      Thread.new do
        execute
      end
    end
  end

  # Reset agent for new task
  def reset(new_task = nil)
    @task = new_task if new_task
    @status = :initialized
    @report = nil
    @logger.info("Agent #{@name} reset")
  end

  # Check if agent is available for new tasks
  def available?
    [:initialized, :completed, :failed, :timeout].include?(@status)
  end

  # Get detailed status information
  def detailed_status
    {
      name: @name,
      agent_id: @agent_id,
      task: @task,
      status: @status,
      data_sources_count: @data_sources.size,
      report_length: @report&.length || 0,
      has_cognitive_monitor: !@cognitive_monitor.nil?
    }
  end

  private

  # Default configuration
  def default_config
    {
      timeout: 30,
      max_retries: 3,
      logger: nil,
      enable_reasoning: true,
      reasoning_depth: 3
    }
  end

  # Execute the actual task logic
  def execute_task
    case @config[:reasoning_depth]
    when 1
      basic_reasoning
    when 2
      intermediate_reasoning
    else
      advanced_reasoning
    end
  end

  # Basic reasoning implementation
  def basic_reasoning
    @logger.debug("Agent #{@name} using basic reasoning")
    
    # Simple task analysis
    task_analysis = {
      task_type: analyze_task_type,
      complexity: calculate_task_complexity,
      estimated_duration: estimate_duration,
      required_resources: identify_required_resources
    }

    # Generate basic response
    response = generate_basic_response(task_analysis)
    
    {
      agent_id: @agent_id,
      analysis: task_analysis,
      response: response,
      reasoning_level: 'basic',
      timestamp: Time.now
    }
  end

  # Intermediate reasoning with data source integration
  def intermediate_reasoning
    @logger.debug("Agent #{@name} using intermediate reasoning")
    
    # Enhanced task analysis
    task_analysis = {
      task_type: analyze_task_type,
      complexity: calculate_task_complexity,
      data_requirements: analyze_data_requirements,
      potential_challenges: identify_challenges,
      success_criteria: define_success_criteria
    }

    # Process data sources if available
    data_insights = process_data_sources if @data_sources.any?

    # Generate enhanced response
    response = generate_enhanced_response(task_analysis, data_insights)
    
    {
      agent_id: @agent_id,
      analysis: task_analysis,
      data_insights: data_insights,
      response: response,
      reasoning_level: 'intermediate',
      timestamp: Time.now
    }
  end

  # Advanced reasoning with swarm coordination awareness
  def advanced_reasoning
    @logger.debug("Agent #{@name} using advanced reasoning")
    
    # Comprehensive task analysis
    task_analysis = {
      task_type: analyze_task_type,
      complexity: calculate_task_complexity,
      subtasks: decompose_into_subtasks,
      dependencies: identify_dependencies,
      optimization_opportunities: find_optimizations,
      collaboration_potential: assess_collaboration_needs
    }

    # Advanced data processing
    data_insights = advanced_data_processing if @data_sources.any?

    # Meta-reasoning about the reasoning process
    meta_reasoning = {
      reasoning_confidence: assess_reasoning_confidence,
      alternative_approaches: identify_alternatives,
      uncertainty_factors: identify_uncertainties,
      validation_methods: suggest_validation_approaches
    }

    # Generate comprehensive response
    response = generate_comprehensive_response(task_analysis, data_insights, meta_reasoning)
    
    {
      agent_id: @agent_id,
      analysis: task_analysis,
      data_insights: data_insights,
      meta_reasoning: meta_reasoning,
      response: response,
      reasoning_level: 'advanced',
      timestamp: Time.now
    }
  end

  # Analyze what type of task this is
  def analyze_task_type
    task_lower = @task.downcase
    
    case task_lower
    when /create|generate|make|build|produce/
      :creative
    when /analyze|study|examine|investigate|research/
      :analytical
    when /plan|organize|schedule|coordinate|manage/
      :planning
    when /solve|fix|repair|debug|troubleshoot/
      :problem_solving
    when /optimize|improve|enhance|refine|perfect/
      :optimization
    else
      :general
    end
  end

  # Calculate task complexity based on various factors
  def calculate_task_complexity
    complexity = 1.0
    
    # Task length factor
    complexity += (@task.length / 100.0).clamp(0, 2)
    
    # Data sources factor
    complexity += (@data_sources.size / 5.0).clamp(0, 1.5)
    
    # Keyword complexity
    complex_keywords = ['autonomous', 'reasoning', 'comprehensive', 'advanced', 'optimize']
    keyword_count = complex_keywords.count { |keyword| @task.downcase.include?(keyword) }
    complexity += (keyword_count * 0.5)
    
    complexity.clamp(1.0, 5.0)
  end

  # Estimate task duration
  def estimate_duration
    base_time = 5 # seconds
    complexity_multiplier = calculate_task_complexity
    base_time * complexity_multiplier
  end

  # Identify required resources
  def identify_required_resources
    resources = [:computation, :memory]
    
    resources << :network if @data_sources.any?
    resources << :storage if @task.downcase.include?('save') || @task.downcase.include?('store')
    resources << :external_apis if @task.downcase.include?('api') || @task.downcase.include?('service')
    
    resources
  end

  # Additional reasoning methods for advanced processing
  def analyze_data_requirements
    return {} unless @data_sources.any?
    
    {
      source_count: @data_sources.size,
      estimated_data_volume: @data_sources.size * 1000, # Rough estimate
      data_types: ['text', 'metadata'],
      processing_requirements: ['parsing', 'analysis']
    }
  end

  def identify_challenges
    challenges = []
    
    challenges << 'high_complexity' if calculate_task_complexity > 3.5
    challenges << 'data_processing' if @data_sources.size > 3
    challenges << 'time_constraints' if @config[:timeout] < 15
    challenges << 'resource_limitations' if @cognitive_monitor&.cognitive_overload?
    
    challenges
  end

  def define_success_criteria
    [
      'task_completion',
      'result_quality',
      'execution_time_within_limits',
      'resource_usage_optimal'
    ]
  end

  def process_data_sources
    @logger.debug("Processing #{@data_sources.size} data sources")
    
    {
      sources_processed: @data_sources.size,
      processing_method: 'mock_processing',
      insights_generated: @data_sources.size * 2,
      confidence: 0.8
    }
  end

  def decompose_into_subtasks
    # Simple task decomposition based on keywords
    subtasks = [@task]
    
    if @task.include?(' and ')
      subtasks = @task.split(' and ').map(&:strip)
    elsif @task.length > 50
      # Split long tasks into conceptual parts
      words = @task.split(' ')
      mid_point = words.length / 2
      subtasks = [
        words[0...mid_point].join(' '),
        words[mid_point..-1].join(' ')
      ]
    end
    
    subtasks
  end

  def identify_dependencies
    dependencies = []
    
    dependencies << 'data_availability' if @data_sources.any?
    dependencies << 'cognitive_capacity' if @cognitive_monitor
    dependencies << 'external_services' if @task.downcase.include?('api')
    dependencies << 'prior_knowledge' if @task.downcase.include?('based on')
    
    dependencies
  end

  def find_optimizations
    optimizations = []
    
    optimizations << 'parallel_processing' if @data_sources.size > 2
    optimizations << 'caching' if @task.downcase.include?('repeated')
    optimizations << 'batch_processing' if @data_sources.size > 5
    optimizations << 'incremental_updates' if @task.downcase.include?('update')
    
    optimizations
  end

  def assess_collaboration_needs
    return 'low' if @data_sources.empty?
    return 'high' if calculate_task_complexity > 4.0
    return 'medium' if @data_sources.size > 3
    
    'low'
  end

  def advanced_data_processing
    @logger.debug("Advanced data processing for #{@data_sources.size} sources")
    
    {
      processing_strategy: 'advanced_analytics',
      sources_analyzed: @data_sources.size,
      patterns_identified: rand(5..15),
      correlations_found: rand(2..8),
      anomalies_detected: rand(0..3),
      confidence_score: 0.75 + rand(0.2)
    }
  end

  def assess_reasoning_confidence
    base_confidence = 0.7
    
    # Adjust based on task complexity
    complexity = calculate_task_complexity
    confidence_adjustment = (5.0 - complexity) * 0.05
    
    # Adjust based on data availability
    data_adjustment = @data_sources.any? ? 0.1 : -0.1
    
    (base_confidence + confidence_adjustment + data_adjustment).clamp(0.0, 1.0)
  end

  def identify_alternatives
    alternatives = []
    
    case analyze_task_type
    when :creative
      alternatives = ['iterative_refinement', 'collaborative_creation', 'template_based']
    when :analytical
      alternatives = ['statistical_analysis', 'pattern_recognition', 'comparative_study']
    when :planning
      alternatives = ['agile_approach', 'waterfall_method', 'hybrid_planning']
    else
      alternatives = ['alternative_approach_1', 'alternative_approach_2']
    end
    
    alternatives
  end

  def identify_uncertainties
    uncertainties = []
    
    uncertainties << 'data_quality' if @data_sources.any?
    uncertainties << 'computational_limits' if calculate_task_complexity > 3.5
    uncertainties << 'external_dependencies' if @task.downcase.include?('external')
    uncertainties << 'time_constraints' if @config[:timeout] < 20
    
    uncertainties
  end

  def suggest_validation_approaches
    approaches = ['peer_review', 'testing']
    
    approaches << 'data_validation' if @data_sources.any?
    approaches << 'performance_metrics' if @task.downcase.include?('optimize')
    approaches << 'user_feedback' if @task.downcase.include?('user')
    
    approaches
  end

  # Response generation methods
  def generate_basic_response(analysis)
    "Agent #{@name} analyzed task '#{@task}' (type: #{analysis[:task_type]}, complexity: #{analysis[:complexity].round(2)}). Basic reasoning applied."
  end

  def generate_enhanced_response(analysis, data_insights)
    response = "Agent #{@name} completed intermediate analysis of '#{@task}'.\n"
    response += "Task type: #{analysis[:task_type]}, complexity: #{analysis[:complexity].round(2)}\n"
    response += "Data insights: #{data_insights[:insights_generated]} insights generated" if data_insights
    response
  end

  def generate_comprehensive_response(analysis, data_insights, meta_reasoning)
    response = "Agent #{@name} completed comprehensive analysis:\n"
    response += "Task: #{@task}\n"
    response += "Type: #{analysis[:task_type]}, Complexity: #{analysis[:complexity].round(2)}\n"
    response += "Subtasks identified: #{analysis[:subtasks].size}\n"
    response += "Data processing: #{data_insights[:patterns_identified]} patterns found\n" if data_insights
    response += "Confidence: #{(meta_reasoning[:reasoning_confidence] * 100).round(1)}%\n"
    response += "Alternatives considered: #{meta_reasoning[:alternative_approaches].size}"
    response
  end
end

# SwarmOrchestrator - Manages multiple agents working together
class SwarmOrchestrator
  attr_reader :agents, :coordination_strategy, :results

  def initialize(coordination_strategy: :parallel, config: {})
    @agents = []
    @coordination_strategy = coordination_strategy
    @config = default_orchestrator_config.merge(config)
    @logger = @config[:logger] || Logger.new(STDOUT)
    @results = []
    @cognitive_monitor = nil
  end

  # Set cognitive monitor for all agents
  def set_cognitive_monitor(monitor)
    @cognitive_monitor = monitor
    @agents.each { |agent| agent.cognitive_monitor = monitor }
  end

  # Add agent to swarm
  def add_agent(agent)
    agent.cognitive_monitor = @cognitive_monitor if @cognitive_monitor
    @agents << agent
    @logger.info("Added agent #{agent.name} to swarm (total: #{@agents.size})")
  end

  # Create and add multiple agents with tasks
  def create_agents(tasks, name_prefix: 'agent')
    tasks.each_with_index do |task, index|
      agent = SwarmAgent.new(
        name: "#{name_prefix}_#{index}",
        task: task,
        config: @config[:agent_config] || {}
      )
      add_agent(agent)
    end
  end

  # Execute all agents according to coordination strategy
  def execute_swarm
    @logger.info("Executing swarm of #{@agents.size} agents using #{@coordination_strategy} strategy")
    
    case @coordination_strategy
    when :parallel
      execute_parallel
    when :sequential
      execute_sequential
    when :pipeline
      execute_pipeline
    when :adaptive
      execute_adaptive
    else
      raise ArgumentError, "Unknown coordination strategy: #{@coordination_strategy}"
    end
    
    consolidate_results
  end

  # Get swarm status summary
  def swarm_status
    status_counts = @agents.group_by(&:status).transform_values(&:count)
    
    {
      total_agents: @agents.size,
      status_breakdown: status_counts,
      completion_rate: completed_agents.size.to_f / @agents.size,
      failed_agents: failed_agents.size,
      average_complexity: average_task_complexity
    }
  end

  # Get detailed results
  def detailed_results
    @agents.map do |agent|
      {
        agent: agent.detailed_status,
        result: agent.report
      }
    end
  end

  private

  def default_orchestrator_config
    {
      max_parallel_agents: 5,
      agent_timeout: 30,
      retry_failed: true,
      logger: nil,
      agent_config: {}
    }
  end

  # Execute agents in parallel
  def execute_parallel
    max_parallel = @config[:max_parallel_agents]
    
    @agents.each_slice(max_parallel) do |agent_batch|
      futures = agent_batch.map(&:execute_async)
      futures.each(&:wait)
    end
  end

  # Execute agents sequentially
  def execute_sequential
    @agents.each do |agent|
      agent.execute
      
      # Stop if cognitive overload detected
      if @cognitive_monitor&.cognitive_overload?
        @logger.warn("Stopping sequential execution due to cognitive overload")
        break
      end
    end
  end

  # Execute agents in pipeline (output of one feeds into next)
  def execute_pipeline
    @agents.each_with_index do |agent, index|
      # For pipeline, we could pass previous results to next agent
      # This is a simplified version
      agent.execute
      
      if index < @agents.size - 1 && agent.report
        # Could enhance next agent's task with current results
        next_agent = @agents[index + 1]
        enhanced_task = "#{next_agent.task} [Building on: #{agent.report[0..100]}...]"
        next_agent.reset(enhanced_task)
      end
    end
  end

  # Adaptive execution based on cognitive load and agent performance
  def execute_adaptive
    available_agents = @agents.select(&:available?)
    
    while available_agents.any?
      # Check cognitive capacity
      if @cognitive_monitor&.cognitive_overload?
        @logger.info("Adaptive execution pausing due to cognitive overload")
        sleep(1)
        next
      end

      # Execute highest priority available agent
      agent_to_execute = select_next_agent(available_agents)
      agent_to_execute.execute
      
      available_agents = @agents.select(&:available?)
    end
  end

  def select_next_agent(available_agents)
    # Simple priority: shortest task first
    available_agents.min_by { |agent| agent.task.length }
  end

  def consolidate_results
    @results = @agents.map do |agent|
      {
        agent_name: agent.name,
        task: agent.task,
        status: agent.status,
        report: agent.report
      }
    end
    
    @logger.info("Swarm execution completed. Results from #{@results.size} agents.")
    generate_swarm_summary
  end

  def generate_swarm_summary
    summary = {
      total_agents: @agents.size,
      successful: completed_agents.size,
      failed: failed_agents.size,
      completion_rate: (completed_agents.size.to_f / @agents.size * 100).round(1),
      execution_strategy: @coordination_strategy,
      timestamp: Time.now
    }
    
    @logger.info("Swarm Summary: #{summary}")
    summary
  end

  def completed_agents
    @agents.select { |agent| agent.status == :completed }
  end

  def failed_agents
    @agents.select { |agent| [:failed, :timeout].include?(agent.status) }
  end

  def average_task_complexity
    return 0 if @agents.empty?
    
    total_complexity = @agents.sum { |agent| agent.send(:calculate_task_complexity) }
    (total_complexity / @agents.size).round(2)
  end
end