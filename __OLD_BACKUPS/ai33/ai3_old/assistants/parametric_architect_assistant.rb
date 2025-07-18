# frozen_string_literal: true

# Parametric Architect Assistant
# This assistant works closely with the Material Repurposing Assistant to design sustainable, high-efficiency buildings using repurposed materials.

require 'langchainrb'

class ParametricArchitectAssistant
  def initialize
    @model = Langchainrb::LLM::OpenAI.new(api_key: ENV.fetch('OPENAI_API_KEY', nil))
  end

  # Generate parametric designs using repurposed materials
  def generate_parametric_design(_materials)
    prompt = "Create parametric architectural designs using the following repurposed materials: \#{materials.join(', ')}."
    response = @model.completion(prompt: prompt)
    store_response('Parametric Design Suggestions:', response)
  end

  # Other methods...
end
