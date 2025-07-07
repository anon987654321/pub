# -*- encoding: utf-8 -*-
# stub: ruby-openai 3.7.0 ruby lib

Gem::Specification.new do |s|
  s.name = "ruby-openai".freeze
  s.version = "3.7.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "changelog_uri" => "https://github.com/alexrudall/ruby-openai/blob/main/CHANGELOG.md", "homepage_uri" => "https://github.com/alexrudall/ruby-openai", "rubygems_mfa_required" => "true", "source_code_uri" => "https://github.com/alexrudall/ruby-openai" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Alex".freeze]
  s.bindir = "exe".freeze
  s.date = "2023-03-25"
  s.email = ["alexrudall@users.noreply.github.com".freeze]
  s.homepage = "https://github.com/alexrudall/ruby-openai".freeze
  s.licenses = ["MIT".freeze]
  s.post_install_message = "Note if upgrading: The `::Ruby::OpenAI` module has been removed and all classes have been moved under the top level `::OpenAI` module. To upgrade, change `require 'ruby/openai'` to `require 'openai'` and change all references to `Ruby::OpenAI` to `OpenAI`.".freeze
  s.required_ruby_version = Gem::Requirement.new(">= 2.6.0".freeze)
  s.rubygems_version = "3.4.20".freeze
  s.summary = "OpenAI API + Ruby! \u{1F916}\u2764\uFE0F".freeze

  s.installed_by_version = "3.4.20" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<httparty>.freeze, [">= 0.18.1"])
end
