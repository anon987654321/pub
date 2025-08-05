# lib/tool_manager.rb
#
# ToolManager: Handles execution of integrated tools.
# Loads available tools dynamically from the lib directory.

require_relative "filesystem_tool"
require_relative "universal_scraper"

class ToolManager
  TOOLS = {
    "filesystem" => FileSystemTool.new,
    "scraper" => UniversalScraper.new
  }

  def run_tool(tool_name, *args)
    tool = TOOLS[tool_name.downcase]
    return "Tool not found" unless tool

    tool.execute(*args)
  rescue StandardError => e
    "Error executing tool: #{e.message}"
  end
end

