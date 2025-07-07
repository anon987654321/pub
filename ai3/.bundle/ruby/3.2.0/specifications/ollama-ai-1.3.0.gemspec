# -*- encoding: utf-8 -*-
# stub: ollama-ai 1.3.0 ruby ports/dsl

Gem::Specification.new do |s|
  s.name = "ollama-ai".freeze
  s.version = "1.3.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "allowed_push_host" => "https://rubygems.org", "homepage_uri" => "https://github.com/gbaptista/ollama-ai", "rubygems_mfa_required" => "true", "source_code_uri" => "https://github.com/gbaptista/ollama-ai" } if s.respond_to? :metadata=
  s.require_paths = ["ports/dsl".freeze]
  s.authors = ["gbaptista".freeze]
  s.date = "2024-07-21"
  s.description = "A Ruby gem for interacting with Ollama's API that allows you to run open source AI LLMs (Large Language Models) locally.".freeze
  s.homepage = "https://github.com/gbaptista/ollama-ai".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 3.1.0".freeze)
  s.rubygems_version = "3.4.20".freeze
  s.summary = "Interact with Ollama API to run open source AI models locally.".freeze

  s.installed_by_version = "3.4.20" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<faraday>.freeze, ["~> 2.10"])
  s.add_runtime_dependency(%q<faraday-typhoeus>.freeze, ["~> 1.1"])
  s.add_runtime_dependency(%q<typhoeus>.freeze, ["~> 1.4", ">= 1.4.1"])
end
