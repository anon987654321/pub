# frozen_string_literal: true

# § Minigpt

#!/usr/bin/env ruby
# frozen_string_literal: true
#
# MiniGPT v1.2 — minimal CLI for Grok, Claude Instant, and OpenAI
#
# gem install langchainrb
#

begin
  require "langchain"
rescue LoadError
  abort "Please `gem install langchainrb` before running."
end

# Prompt for API keys if missing
api_keys = {
  "GEMINI" => ENV["GOOGLE_API_KEY"],
  "CLAUDE" => ENV["ANTHROPIC_API_KEY"],
  "OPENAI" => ENV["OPENAI_API_KEY"]
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
  "Grok (Google Gemini)" => Langchain::LLM::GoogleGemini.new(
    api_key: api_keys["GEMINI"]
  ),
  "Claude Instant" => Langchain::LLM::Anthropic.new(
    api_key: api_keys["CLAUDE"]
  ),
  "OpenAI" => Langchain::LLM::OpenAI.new(
    api_key: api_keys["OPENAI"]
  )
}

# Rotating spinner for progress
def rotating_animation(thread)
  begin
    spinner = ["/", "-", "\", "|"]
    index = 0
    while thread.alive?
      print "\r#{spinner[index]}"
      index += 1
      if index >= spinner.length
        index = 0
      end
      sleep(0.1)
    end
    print "\r"
  rescue StandardError => e
    # TODO: Add proper error handling
    raise e
  end
end

# Extract response uniformly
def extract_response(resp)
  begin
    if resp.respond_to?("content")
      resp.content
    elsif resp.is_a?(Hash)
      resp.dig("choices", 0, "message", "content")
    else
      resp.to_s
    end
  rescue StandardError => e
    # TODO: Add proper error handling
    raise e
  end
end

puts "MiniGPT: compare responses from three LLMs"

loop do
  print "\n> "
  input_line = gets
  if input_line.nil?
    break
  end
  input = input_line.chomp
  if input.strip.empty?
    break
  end

  clients.each do |name, client|
    begin
      response_thread = Thread.new do
        client.chat(
          messages: [
            { role: "user", content: input }
          ]
        )
      end
      rotating_animation(response_thread)
      response = response_thread.value
      puts "\n[#{name}]\n#{extract_response(response)}"
    rescue StandardError => e
      warn "[#{name} failed] #{e.message}"
    end
  end

  puts "\n— done —\n"
end

# EOF: 100 lines
# SHA256: c26b63c3953d1f5be86074ceb1e5c3c867337ab807faa6694354d1f7f7d5944f