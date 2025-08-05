# frozen_string_literal: true

# swarm_agent.rb - Swarm agent patterns extracted from musicians.rb

class SwarmAgent
  attr_reader :id, :role, :status, :cognitive_load
  
  def initialize(id:, role:, config: {})
    @id = id
    @role = role
    @config = config
    @status = :idle
    @cognitive_load = 0.0
    @created_at = Time.now
    @task_queue = []
  end

  # Core swarm agent functionality
  def assign_task(task)
    return false if @status == :busy || cognitive_overload?
    
    @task_queue << task
    @status = :assigned
    update_cognitive_load(task[:complexity] || 1.0)
    true
  end

  def execute_task
    return nil if @task_queue.empty?
    
    @status = :busy
    task = @task_queue.shift
    
    # Simulate task execution
    result = process_task(task)
    
    @status = :idle
    reduce_cognitive_load(0.1)
    
    result
  end

  def cognitive_overload?
    @cognitive_load > 5.0
  end

  def status_report
    {
      id: @id,
      role: @role,
      status: @status,
      cognitive_load: @cognitive_load,
      queue_size: @task_queue.size,
      uptime: Time.now - @created_at
    }
  end

  # Create specialized music agents (from musicians.rb pattern)
  def self.create_music_swarm(size = 10)
    genres = %w[rock jazz classical electronic hip_hop folk country blues metal experimental]
    
    genres.first(size).map.with_index do |genre, index|
      new(
        id: "music_agent_#{index + 1}",
        role: "#{genre}_specialist",
        config: { genre: genre, expertise_level: rand(7..10) }
      )
    end
  end

  private

  def process_task(task)
    # Task processing logic based on role and task type
    case @role
    when /music/
      process_music_task(task)
    when /analysis/
      process_analysis_task(task)
    else
      process_generic_task(task)
    end
  end

  def process_music_task(task)
    {
      agent_id: @id,
      result: "Music task processed for #{@config[:genre]}",
      task_id: task[:id],
      recommendations: generate_music_recommendations,
      execution_time: rand(0.5..2.0)
    }
  end

  def process_analysis_task(task)
    {
      agent_id: @id,
      result: "Analysis completed by #{@role}",
      task_id: task[:id],
      insights: ["Pattern detected", "Anomaly found", "Trend identified"].sample,
      execution_time: rand(1.0..3.0)
    }
  end

  def process_generic_task(task)
    {
      agent_id: @id,
      result: "Task completed by #{@role}",
      task_id: task[:id],
      execution_time: rand(0.2..1.0)
    }
  end

  def generate_music_recommendations
    genre = @config[:genre] || "general"
    [
      "#{genre.capitalize} track recommendation",
      "Collaboration suggestion for #{genre}",
      "#{genre.capitalize} production technique"
    ]
  end

  def update_cognitive_load(complexity)
    @cognitive_load = [@cognitive_load + complexity, 10.0].min
  end

  def reduce_cognitive_load(amount)
    @cognitive_load = [@cognitive_load - amount, 0.0].max
  end
end