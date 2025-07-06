#!/usr/bin/env ruby
require_relative '__shared.sh'

class MedicalAssistant
  def initialize
    @knowledge_sources = [
      "https://pubmed.ncbi.nlm.nih.gov/",
      "https://mayoclinic.org/",
      "https://who.int/"
    ]
  end

  def lookup_condition(condition)
    puts "Searching for information on: #{condition}"
  end

  def provide_medical_advice(symptoms)
    prompt = "Given the symptoms described, provide medical advice or potential conditions."
    puts format_prompt(create_prompt(prompt, [symptoms]), {})
  end
end
