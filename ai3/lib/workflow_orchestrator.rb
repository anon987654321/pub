# frozen_string_literal: true

# workflow_orchestrator.rb - DAG-based task chaining

class WorkflowOrchestrator
  attr_reader :workflows, :execution_history

  def initialize
    @workflows = {}
    @execution_history = []
    @running_workflows = {}
  end

  # Define a new workflow with DAG structure
  def define_workflow(name, definition)
    validate_workflow_definition(definition)
    
    @workflows[name] = {
      definition: definition,
      created_at: Time.now,
      executions: 0
    }
  end

  # Execute a workflow
  def execute_workflow(name, input_data = {})
    workflow = @workflows[name]
    return { error: "Workflow '#{name}' not found" } unless workflow

    execution_id = generate_execution_id
    
    @running_workflows[execution_id] = {
      name: name,
      status: :running,
      started_at: Time.now,
      input_data: input_data,
      results: {},
      completed_tasks: [],
      failed_tasks: []
    }

    begin
      result = execute_dag(workflow[:definition], input_data, execution_id)
      @running_workflows[execution_id][:status] = :completed
      @running_workflows[execution_id][:completed_at] = Time.now
      
      # Add to history
      @execution_history << @running_workflows[execution_id].dup
      @workflows[name][:executions] += 1
      
      result
    rescue StandardError => e
      @running_workflows[execution_id][:status] = :failed
      @running_workflows[execution_id][:error] = e.message
      @running_workflows[execution_id][:failed_at] = Time.now
      
      { error: "Workflow execution failed: #{e.message}" }
    ensure
      @running_workflows.delete(execution_id)
    end
  end

  # Get workflow status
  def workflow_status(execution_id = nil)
    if execution_id
      @running_workflows[execution_id] || @execution_history.find { |h| h[:execution_id] == execution_id }
    else
      {
        running: @running_workflows.keys.size,
        total_executions: @execution_history.size,
        workflows_defined: @workflows.size
      }
    end
  end

  # List available workflows
  def list_workflows
    @workflows.keys
  end

  private

  def validate_workflow_definition(definition)
    raise ArgumentError, "Workflow definition must be a hash" unless definition.is_a?(Hash)
    raise ArgumentError, "Workflow must have tasks" unless definition[:tasks]
    raise ArgumentError, "Tasks must be an array" unless definition[:tasks].is_a?(Array)
    
    # Validate each task has required fields
    definition[:tasks].each do |task|
      raise ArgumentError, "Task must have an id" unless task[:id]
      raise ArgumentError, "Task must have an action" unless task[:action]
    end
  end

  def execute_dag(definition, input_data, execution_id)
    tasks = definition[:tasks]
    dependencies = build_dependency_graph(tasks)
    results = {}
    
    # Execute tasks in dependency order
    execution_order = topological_sort(dependencies)
    
    execution_order.each do |task_id|
      task = tasks.find { |t| t[:id] == task_id }
      next unless task
      
      # Get input data for this task
      task_input = prepare_task_input(task, results, input_data)
      
      # Execute task
      task_result = execute_task(task, task_input, execution_id)
      results[task_id] = task_result
      
      @running_workflows[execution_id][:completed_tasks] << task_id
      
      # Check if task failed
      if task_result[:status] == :failed
        @running_workflows[execution_id][:failed_tasks] << task_id
        
        # If task is critical, fail the workflow
        if task[:critical] != false
          raise StandardError, "Critical task #{task_id} failed: #{task_result[:error]}"
        end
      end
    end
    
    {
      execution_id: execution_id,
      status: :completed,
      results: results,
      summary: generate_execution_summary(results)
    }
  end

  def build_dependency_graph(tasks)
    graph = {}
    
    tasks.each do |task|
      task_id = task[:id]
      dependencies = task[:depends_on] || []
      graph[task_id] = dependencies
    end
    
    graph
  end

  def topological_sort(graph)
    # Simple topological sort implementation
    visited = Set.new
    temp_visited = Set.new
    result = []
    
    def visit(node, graph, visited, temp_visited, result)
      return if visited.include?(node)
      raise StandardError, "Circular dependency detected" if temp_visited.include?(node)
      
      temp_visited.add(node)
      
      graph[node]&.each do |dependency|
        visit(dependency, graph, visited, temp_visited, result)
      end
      
      temp_visited.delete(node)
      visited.add(node)
      result << node
    end
    
    graph.keys.each do |node|
      visit(node, graph, visited, temp_visited, result) unless visited.include?(node)
    end
    
    result
  end

  def prepare_task_input(task, previous_results, initial_input)
    task_input = initial_input.dup
    
    # Add results from dependent tasks
    dependencies = task[:depends_on] || []
    dependencies.each do |dep_id|
      if previous_results[dep_id]
        task_input["#{dep_id}_result"] = previous_results[dep_id][:output]
      end
    end
    
    task_input
  end

  def execute_task(task, input_data, execution_id)
    start_time = Time.now
    
    begin
      # Execute the task action
      output = case task[:action]
               when :scrape_url
                 execute_scrape_action(task, input_data)
               when :analyze_data
                 execute_analysis_action(task, input_data)
               when :generate_report
                 execute_report_action(task, input_data)
               when :process_llm
                 execute_llm_action(task, input_data)
               else
                 execute_custom_action(task, input_data)
               end
      
      {
        task_id: task[:id],
        status: :completed,
        output: output,
        execution_time: Time.now - start_time,
        input_data: input_data
      }
    rescue StandardError => e
      {
        task_id: task[:id],
        status: :failed,
        error: e.message,
        execution_time: Time.now - start_time,
        input_data: input_data
      }
    end
  end

  def execute_scrape_action(task, input_data)
    url = task[:params][:url] || input_data[:url]
    { scraped_content: "Mock scraped content from #{url}" }
  end

  def execute_analysis_action(task, input_data)
    { analysis_result: "Mock analysis of provided data", insights: ["Pattern 1", "Trend 2"] }
  end

  def execute_report_action(task, input_data)
    { report: "Generated report based on input data", format: "markdown" }
  end

  def execute_llm_action(task, input_data)
    prompt = task[:params][:prompt] || "Analyze the following data"
    { llm_response: "Mock LLM response to: #{prompt}" }
  end

  def execute_custom_action(task, input_data)
    { result: "Custom action #{task[:action]} executed", input_received: input_data.keys }
  end

  def generate_execution_summary(results)
    completed = results.values.count { |r| r[:status] == :completed }
    failed = results.values.count { |r| r[:status] == :failed }
    total_time = results.values.sum { |r| r[:execution_time] || 0 }
    
    {
      total_tasks: results.size,
      completed_tasks: completed,
      failed_tasks: failed,
      success_rate: "#{(completed.to_f / results.size * 100).round(1)}%",
      total_execution_time: total_time.round(2)
    }
  end

  def generate_execution_id
    "workflow_#{Time.now.to_i}_#{rand(1000..9999)}"
  end
end