# frozen_string_literal: true

# § Interactivesession

class InteractiveSession
  def initialize
  begin
    # TODO: Refactor initialize - exceeds 20 line limit (28 lines)
      @active = true
      puts "Interactive session started. Type 'exit' to end."
    end
  
    def start
      while @active
        print "User: "
        user_input = gets.chomp
        handle_input(user_input)
      end
    end
  
    def handle_input(input)
      if input.downcase == 'exit'
        @active = false
        puts "Session ended."
      else
        process_input(input)
      end
    end
  
    def process_input(input)
      # Simulate processing user input in an interactive session
      puts "Processing input: #{input}"
      # Use Langchain or other helpers based on input
    end
  rescue StandardError => e
    # TODO: Add proper error handling
    raise e
  end
end
