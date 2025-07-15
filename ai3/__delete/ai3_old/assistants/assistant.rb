# frozen_string_literal: true


# § Assistant

class Assistant
  def initialize(domain_knowledge: nil)
  begin
      @domain_knowledge = domain_knowledge
    end
  
    def get_response(input)
      case @domain_knowledge
      when "social_media"
        "Handling social media queries."
      else
        "Handling general queries."
      end
    end
  rescue StandardError => e
    # TODO: Add proper error handling
    raise e
  end
end