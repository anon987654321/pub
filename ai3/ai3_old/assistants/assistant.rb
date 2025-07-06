
class Assistant
  def initialize(domain_knowledge: nil)
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
end
