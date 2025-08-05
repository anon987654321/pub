# frozen_string_literal: true

# SwarmAgent: Manages multiple autonomous agents working together
# Extracted from musicians.rb pattern for general swarm agent functionality

require 'json'
require 'digest'

class SwarmAgent
  attr_accessor :agents, :task_queue, :results, :orchestrator

  def initialize(specializations, options = {})
    @specializations = specializations
    @options = {
      max_agents: 10,
      task_timeout: 300,
      result_format: :json,
      parallel_execution: true
    }.merge(options)
    
    @agents = []
    @task_queue = []
    @results = {}
    @orchestrator = nil
    
    create_agent_swarm
  end

  def create_agent_swarm
    puts "Creating swarm of #{@specializations.length} autonomous agents..."
    
    @agents = @specializations.map.with_index do |spec, index|
      {
        id: "agent_#{index + 1}",
        name: spec[:name] || spec[:genre] || "Agent #{index + 1}",
        specialization: spec,
        status: 'active',
        capabilities: spec[:skills] || spec[:capabilities] || [],
        focus_area: spec[:focus] || spec[:description] || 'General tasks',
        current_task: nil,
        completed_tasks: 0,
        success_rate: 0.0,
        last_active: Time.now
      }
    end
    
    puts "Swarm initialized with #{@agents.length} agents"
    @agents.each { |agent| puts "  - #{agent[:name]}: #{agent[:focus_area]}" }
  end

  def assign_task(task_description, data = {})
    task = {
      id: generate_task_id,
      description: task_description,
      data: data,
      assigned_agent: nil,
      status: 'pending',
      created_at: Time.now,
      started_at: nil,
      completed_at: nil,
      result: nil
    }
    
    @task_queue << task
    
    if @options[:parallel_execution]
      process_task_parallel(task)
    else
      process_task_sequential(task)
    end
    
    task[:id]
  end

  def assign_specialized_task(specialization_key, task_description, data = {})
    # Find agent best suited for this specialization
    suitable_agent = find_suitable_agent(specialization_key)
    
    if suitable_agent
      task_id = assign_task(task_description, data)
      task = @task_queue.find { |t| t[:id] == task_id }
      task[:assigned_agent] = suitable_agent[:id]
      task[:assigned_to] = suitable_agent[:name]
      
      puts "Task #{task_id} assigned to #{suitable_agent[:name]} (#{specialization_key})"
      task_id
    else
      puts "No suitable agent found for specialization: #{specialization_key}"
      nil
    end
  end

  def execute_swarm_analysis(domain_data)
    puts "Executing swarm analysis with #{@agents.length} agents..."
    
    # Assign tasks to each agent based on their specialization
    task_ids = @agents.map do |agent|
      task_description = "Analyze #{domain_data[:type] || 'data'} from #{agent[:specialization][:genre] || agent[:name]} perspective"
      
      assign_specialized_task(
        agent[:specialization][:genre] || agent[:name],
        task_description,
        { 
          agent_focus: agent[:focus_area],
          capabilities: agent[:capabilities],
          analysis_data: domain_data
        }
      )
    end.compact

    # Wait for all tasks to complete or timeout
    wait_for_completion(task_ids)
    
    # Consolidate results
    consolidate_swarm_results(task_ids)
  end

  def get_swarm_status
    {
      total_agents: @agents.length,
      active_agents: @agents.count { |a| a[:status] == 'active' },
      pending_tasks: @task_queue.count { |t| t[:status] == 'pending' },
      running_tasks: @task_queue.count { |t| t[:status] == 'running' },
      completed_tasks: @task_queue.count { |t| t[:status] == 'completed' },
      average_success_rate: calculate_average_success_rate,
      last_activity: @agents.map { |a| a[:last_active] }.max
    }
  end

  def consolidate_swarm_results(task_ids = nil)
    target_tasks = task_ids ? 
      @task_queue.select { |t| task_ids.include?(t[:id]) } :
      @task_queue.select { |t| t[:status] == 'completed' }

    puts "\n=== Swarm Analysis Results ==="
    puts "Analyzed by #{target_tasks.length} agents"
    puts ""

    consolidated_report = {
      summary: "Analysis from #{target_tasks.length} specialized agents",
      agent_reports: [],
      recommendations: [],
      performance_metrics: get_swarm_status
    }

    target_tasks.each do |task|
      agent = @agents.find { |a| a[:id] == task[:assigned_agent] }
      next unless agent

      report = {
        agent_name: agent[:name],
        specialization: agent[:focus_area],
        capabilities: agent[:capabilities],
        task_result: task[:result] || "Analysis completed for #{task[:description]}",
        completion_time: task[:completed_at] - task[:started_at],
        success: task[:status] == 'completed'
      }

      consolidated_report[:agent_reports] << report
      
      puts "#{agent[:name].upcase}:"
      puts "  Specialization: #{agent[:focus_area]}"
      puts "  Capabilities: #{agent[:capabilities].join(', ')}"
      puts "  Result: #{report[:task_result]}"
      puts "  Completion time: #{report[:completion_time].round(2)}s"
      puts ""
    end

    # Generate high-level recommendations
    consolidated_report[:recommendations] = generate_swarm_recommendations(target_tasks)
    
    puts "=== Swarm Recommendations ==="
    consolidated_report[:recommendations].each_with_index do |rec, i|
      puts "#{i + 1}. #{rec}"
    end

    @results[:latest_consolidation] = consolidated_report
    consolidated_report
  end

  private

  def generate_task_id
    "task_#{Time.now.to_i}_#{rand(1000)}"
  end

  def find_suitable_agent(specialization_key)
    # Find agent with matching specialization
    @agents.find do |agent|
      agent[:specialization][:genre] == specialization_key ||
      agent[:specialization][:name] == specialization_key ||
      agent[:name].downcase.include?(specialization_key.to_s.downcase)
    end || @agents.find { |a| a[:status] == 'active' } # Fallback to any active agent
  end

  def process_task_parallel(task)
    # Simulate parallel task processing
    Thread.new do
      process_task_execution(task)
    end
  end

  def process_task_sequential(task)
    process_task_execution(task)
  end

  def process_task_execution(task)
    task[:status] = 'running'
    task[:started_at] = Time.now
    
    if task[:assigned_agent]
      agent = @agents.find { |a| a[:id] == task[:assigned_agent] }
      agent[:current_task] = task[:id]
      agent[:last_active] = Time.now
    end

    # Simulate task processing time
    processing_time = rand(1..5)
    sleep(processing_time)

    # Simulate task completion
    task[:status] = 'completed'
    task[:completed_at] = Time.now
    task[:result] = simulate_agent_analysis(task)

    if task[:assigned_agent]
      agent = @agents.find { |a| a[:id] == task[:assigned_agent] }
      agent[:current_task] = nil
      agent[:completed_tasks] += 1
      agent[:success_rate] = calculate_agent_success_rate(agent)
    end
  end

  def simulate_agent_analysis(task)
    # This would be replaced with actual AI/LLM analysis in production
    agent = @agents.find { |a| a[:id] == task[:assigned_agent] }
    
    if agent
      "#{agent[:name]} analyzed #{task[:description]} using #{agent[:capabilities].join(', ')} capabilities. " \
      "Focus area: #{agent[:focus_area]}. Analysis completed successfully."
    else
      "Task completed: #{task[:description]}"
    end
  end

  def wait_for_completion(task_ids, timeout = 60)
    start_time = Time.now
    
    loop do
      incomplete_tasks = @task_queue.select do |t|
        task_ids.include?(t[:id]) && !['completed', 'failed'].include?(t[:status])
      end
      
      break if incomplete_tasks.empty?
      break if Time.now - start_time > timeout
      
      sleep(0.5)
    end
  end

  def calculate_average_success_rate
    return 0.0 if @agents.empty?
    
    total_rate = @agents.sum { |a| a[:success_rate] }
    (total_rate / @agents.length).round(2)
  end

  def calculate_agent_success_rate(agent)
    return 0.0 if agent[:completed_tasks] == 0
    
    # For simulation, assume high success rate
    # In production, this would track actual success/failure
    0.95
  end

  def generate_swarm_recommendations(tasks)
    recommendations = []
    
    if tasks.length >= 5
      recommendations << "Multi-agent analysis provides comprehensive coverage across specializations"
    end
    
    if calculate_average_success_rate > 0.9
      recommendations << "High agent performance indicates reliable swarm coordination"
    end
    
    specializations = tasks.map { |t| 
      agent = @agents.find { |a| a[:id] == t[:assigned_agent] }
      agent&.dig(:specialization, :genre) || 'general'
    }.uniq
    
    if specializations.length > 3
      recommendations << "Diverse specialization coverage enables multi-perspective analysis"
    end
    
    recommendations << "Consider cross-agent collaboration for complex multi-domain tasks"
    recommendations << "Regular swarm performance monitoring recommended for optimization"
    
    recommendations
  end
end