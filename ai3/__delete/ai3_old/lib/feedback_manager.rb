# frozen_string_literal: true

class FeedbackManager
  def initialize
    @feedback_log = []
  end

  # Collect feedback and categorize it
  def collect_feedback(user_id, feedback, category)
    @feedback_log << { user: user_id, feedback: feedback, category: category }
    puts "Feedback collected for user #{user_id}: #{feedback} (Category: #{category})"
  end

  # Optimize based on categorized feedback
  def optimize_based_on_feedback
    puts "Analyzing feedback for optimization..."
    tool_manager = ToolManager.new
    @feedback_log.each do |entry|
      case entry[:category]
      when "performance"
        puts "Detected performance issue. Optimizing speed."
        tool_manager.call_tool("performance_optimizer")
      when "accuracy"
        puts "Detected accuracy issue. Adjusting models."
        tool_manager.call_tool("accuracy_checker")
      when "ux"
        puts "Detected UX issue. Improving user interface."
        tool_manager.call_tool("ux_enhancer")
      end
    end
    puts "Optimization complete."
  end
end
