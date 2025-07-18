#!/usr/bin/env ruby
# frozen_string_literal: true

#
# MiniGPT v1.2 — minimal CLI for Grok, Claude Instant, and OpenAI
#
# gem install langchainrb
#

begin
  require 'langchain'
rescue LoadError
  abort 'Please `gem install langchainrb` before running.'
end

# Prompt for API keys if missing
api_keys = {
  'GEMINI' => ENV.fetch('GOOGLE_API_KEY', nil),
  'CLAUDE' => ENV.fetch('ANTHROPIC_API_KEY', nil),
  'OPENAI' => ENV.fetch('OPENAI_API_KEY', nil)
}

api_keys.each do |name, key|
  if key.nil?
    print "Enter #{name} API key: "
    api_keys[name] = gets.chomp
  elsif key.strip.empty?
    print "Enter #{name} API key: "
    api_keys[name] = gets.chomp
  end
end

# Initialize clients
clients = {
  'Grok (Google Gemini)' => Langchain::LLM::GoogleGemini.new(
    api_key: api_keys['GEMINI']
  ),
  'Claude Instant' => Langchain::LLM::Anthropic.new(
    api_key: api_keys['CLAUDE']
  ),
  'OpenAI' => Langchain::LLM::OpenAI.new(
    api_key: api_keys['OPENAI']
  )
}

# Rotating spinner for progress
def rotating_animation(thread)
  spinner = ['/', '-', '\\', '|']
  index = 0
  while thread.alive?
    print "\r#{spinner[index]}"
    index += 1
    index = 0 if index >= spinner.length
    sleep(0.1)
  end
  print "\r"
end

# Extract response uniformly
def extract_response(resp)
  if resp.respond_to?('content')
    resp.content
  elsif resp.is_a?(Hash)
    resp.dig('choices', 0, 'message', 'content')
  else
    resp.to_s
  end
end

puts 'MiniGPT: compare responses from three LLMs'

loop do
  print "\n> "
  input_line = gets
  break if input_line.nil?

  input = input_line.chomp
  break if input.strip.empty?

  clients.each do |name, client|
    response_thread = Thread.new do
      client.chat(
        messages: [
          { role: 'user', content: input }
        ]
      )
    end
    rotating_animation(response_thread)
    response = response_thread.value
    puts "\n[#{name}]\n#{extract_response(response)}"
  rescue StandardError => e
    warn "[#{name} failed] #{e.message}"
  end

  puts "\n— done —\n"
end

# EOF: 100 lines
# SHA256: c26b63c3953d1f5be86074ceb1e5c3c867337ab807faa6694354d1f7f7d5944f
