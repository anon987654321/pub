#!/usr/bin/env ruby
require_relative '__shared.sh'

class ArchitectAssistant
  def initialize
    @memory = Langchain::Memory.new
    @knowledge_sources = [
      'https://archdaily.com/',
      'https://designboom.com/architecture/',
      'https://dezeen.com/',
      'https://archinect.com/'
    ]
  end

  def gather_inspiration
    @knowledge_sources.each do |url|
      puts "Fetching architecture insights from: #{url}"
    end
  end

  def create_design
    prompt = 'Generate a concept design inspired by modern architecture trends.'
    puts format_prompt(create_prompt(prompt, []), {})
  end
end
