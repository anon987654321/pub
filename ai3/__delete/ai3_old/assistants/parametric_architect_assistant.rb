# frozen_string_literal: true


# § Parametricarchitectassistant

# Parametric Architect Assistant
# This assistant works closely with the Material Repurposing Assistant to design sustainable, high-efficiency buildings using repurposed materials.

require 'langchainrb'

class ParametricArchitectAssistant
  def initialize
  begin
      @model = Langchainrb::LLM::OpenAI.new(api_key: ENV['OPENAI_API_KEY'])
    end
  
    # Generate parametric designs using repurposed materials
    def generate_parametric_design(materials)
      prompt = "Create parametric architectural designs using the following repurposed materials: \#{materials.join(', ')}."
      response = @model.completion(prompt: prompt)
      store_response("Parametric Design Suggestions:", response)
    end
  
    # Other methods...
  rescue StandardError => e
    # TODO: Add proper error handling
    raise e
  end
end