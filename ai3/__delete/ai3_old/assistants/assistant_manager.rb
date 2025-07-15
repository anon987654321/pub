# frozen_string_literal: true


# AI3 Assistant Manager - Custom Agent Logic Based on Langchainrb Concepts

class AssistantManager
  def initialize
    @assistants = {}
  end

  # Add an assistant (agent) to the system
  def add_assistant(assistant_name, assistant)
    @assistants[assistant_name] = assistant
    puts "Added assistant: #{assistant_name}"
  end

  # Handle tasks dynamically with assistants
  def handle_task(assistant_name, task)
    assistant = @assistants[assistant_name]
    if assistant
      result = assistant.perform_task(task)
      puts "Task result from #{assistant_name}: #{result}"
      return result
    else
      puts "No assistant found with name: #{assistant_name}"
      return nil
    end
  end
end

# Example assistant (agent) class
class BasicAssistant
  def perform_task(task)
    puts "Performing task: #{task}"
    # Simulate task execution logic
    "Task '#{task}' completed."
  end
end
