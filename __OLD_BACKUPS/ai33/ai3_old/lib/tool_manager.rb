# frozen_string_literal: true

# ToolManager: Manages  loading and usage of various tools for AI3
class ToolManager
  require 'logger'

  def initialize
    @logger = Logger.new(STDOUT)
    @logger.level = Logger::INFO
    @tools = load_tools
    log_message(:info, 'ToolManager initialized with available tools.')
  end

  # Execute a given command using the appropriate tool
  def execute_command(command)
    tool = select_tool_for_command(command)
    if tool
      log_message(:info, "Executing command '#{command}' with tool: #{tool.class.name}")
      tool.execute(command)
    else
      log_message(:warn, "No suitable tool found for command: #{command}")
    end
  rescue StandardError => e
    log_message(:error, "Error executing command: #{e.message}")
  end

  private

  # Load available tools ally from the lib/tools directory
  def load_tools
    tools = []
    tool_files = Dir[File.join(__dir__, 'tools', '*.rb')]
    tool_files.each do |file|
      require file
      tool_class = File.basename(file, '.rb').split('_').collect(&:capitalize).join('').constantize
      tools << tool_class.new
    end
    tools
  rescue StandardError => e
    log_message(:error, "Failed to load tools: #{e.message}")
    []
  end

  # Select the appropriate tool for a given command
  def select_tool_for_command(command)
    @tools.detect { |tool| tool.can_handle?(command) }
  end

  # Log messages with different severity levels
  def log_message(severity, message)
    case severity
    when :info
      @logger.info(message)
    when :warn
      @logger.warn(message)
    when :error
      @logger.error(message)
    else
      @logger.debug(message)
    end
  end
end
