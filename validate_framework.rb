#!/usr/bin/env ruby
# frozen_string_literal: true

# § Framework Validation: v12.9.0 compliance checker
# Validates repository files against extreme scrutiny framework

require 'json'
require 'find'

# § Validator: Master.json v12.9.0 framework validator
class FrameworkValidator
  # § Constants: Validation thresholds
  MAX_FUNCTION_LINES = 20
  MIN_FUNCTION_LINES = 3
  MAX_VARIABLE_NAME_LENGTH = 30
  MIN_VARIABLE_NAME_LENGTH = 5
  MAX_SENTENCE_LENGTH = 15
  MAX_CONCEPTS_PER_SECTION = 7
  MAX_ITERATIONS = 10
  MEMORY_LIMIT = 1_000_000_000  # 1GB
  CPU_LIMIT = 0.1  # 10%

  def initialize
    @validation_results = []
    @total_files = 0
    @compliant_files = 0
    @start_time = Time.now
  end

  # § Validation: Main validation workflow
  def validate_repository
    puts "Starting v12.9.0 framework validation..."
    
    validate_master_json
    validate_ruby_files
    validate_markdown_files
    
    generate_compliance_report
  end

  # § Validation: Master.json compliance check
  def validate_master_json
    master_json_path = "prompts/master.json"
    
    unless File.exist?(master_json_path)
      add_violation("Master.json missing", master_json_path)
      return
    end
    
    config = JSON.parse(File.read(master_json_path))
    validate_master_json_structure(config)
  rescue JSON::ParserError => e
    add_violation("Master.json invalid JSON: #{e.message}", master_json_path)
  end

  # § Validation: Master.json structure validation
  def validate_master_json_structure(config)
    required_sections = [
      "extreme_scrutiny_framework",
      "cognitive_orchestration",
      "anti_truncation"
    ]
    
    core_sections = [
      "code_quality_standards",
      "circuit_breakers",
      "measurement_precision"
    ]
    
    # Check root level sections
    required_sections.each do |section|
      unless config[section]
        add_violation("Missing section: #{section}", "prompts/master.json")
      end
    end
    
    # Check core nested sections
    if config["core"]
      core_sections.each do |section|
        unless config["core"][section]
          add_violation("Missing section: #{section}", "prompts/master.json")
        end
      end
    else
      add_violation("Missing core section", "prompts/master.json")
    end
    
    validate_version_compliance(config)
  end

  # § Validation: Version compliance check
  def validate_version_compliance(config)
    meta = config["meta"]
    return unless meta
    
    unless meta["version"] == "v12.9.0"
      add_violation("Incorrect version: #{meta['version']}", "prompts/master.json")
    end
  end

  # § Validation: Ruby files compliance
  def validate_ruby_files
    Find.find('.') do |path|
      next unless path.end_with?('.rb')
      next if path.include?('/.bundle/')
      next if path.include?('/vendor/')
      
      @total_files += 1
      validate_ruby_file(path)
    end
  end

  # § Validation: Individual Ruby file validation
  def validate_ruby_file(file_path)
    content = File.read(file_path)
    
    validate_frozen_string_literal(content, file_path)
    validate_cognitive_headers(content, file_path)
    validate_function_lengths(content, file_path)
    validate_variable_names(content, file_path)
    validate_circuit_breaker_patterns(content, file_path)
    
    @compliant_files += 1
  rescue StandardError => e
    add_violation("File validation error: #{e.message}", file_path)
  end

  # § Validation: Frozen string literal requirement
  def validate_frozen_string_literal(content, file_path)
    unless content.include?("# frozen_string_literal: true")
      add_violation("Missing frozen_string_literal", file_path)
    end
  end

  # § Validation: Cognitive headers requirement
  def validate_cognitive_headers(content, file_path)
    header_count = content.scan(/# §/).length
    line_count = content.lines.length
    
    if header_count == 0 && line_count > 50
      add_violation("Missing cognitive headers", file_path)
    end
  end

  # § Validation: Function length compliance
  def validate_function_lengths(content, file_path)
    functions = extract_functions(content)
    
    functions.each do |func|
      line_count = func[:lines].length
      
      if line_count > MAX_FUNCTION_LINES
        add_violation("Function too long: #{func[:name]} (#{line_count} lines)", file_path)
      elsif line_count < MIN_FUNCTION_LINES
        add_violation("Function too short: #{func[:name]} (#{line_count} lines)", file_path)
      end
    end
  end

  # § Validation: Variable name compliance
  def validate_variable_names(content, file_path)
    variable_names = extract_variable_names(content)
    
    variable_names.each do |var_name|
      if var_name.length > MAX_VARIABLE_NAME_LENGTH
        add_violation("Variable name too long: #{var_name}", file_path)
      elsif var_name.length < MIN_VARIABLE_NAME_LENGTH
        add_violation("Variable name too short: #{var_name}", file_path)
      end
    end
  end

  # § Validation: Circuit breaker pattern detection
  def validate_circuit_breaker_patterns(content, file_path)
    has_loops = content.match?(/while|loop|each|times/)
    has_circuit_breaker = content.include?("max_iterations") || 
                         content.include?("circuit_breaker") ||
                         content.include?("MAX_ITERATIONS")
    
    if has_loops && !has_circuit_breaker
      add_violation("Missing circuit breaker in loops", file_path)
    end
  end

  # § Validation: Markdown files validation
  def validate_markdown_files
    Find.find('.') do |path|
      next unless path.end_with?('.md')
      
      @total_files += 1
      validate_markdown_file(path)
    end
  end

  # § Validation: Individual Markdown file validation
  def validate_markdown_file(file_path)
    content = File.read(file_path)
    
    validate_sentence_length(content, file_path)
    validate_cognitive_load(content, file_path)
    
    @compliant_files += 1
  rescue StandardError => e
    add_violation("Markdown validation error: #{e.message}", file_path)
  end

  # § Validation: Sentence length compliance
  def validate_sentence_length(content, file_path)
    sentences = content.split(/[.!?]/)
    
    sentences.each do |sentence|
      word_count = sentence.split.length
      
      if word_count > MAX_SENTENCE_LENGTH
        add_violation("Sentence too long: #{word_count} words", file_path)
      end
    end
  end

  # § Validation: Cognitive load assessment
  def validate_cognitive_load(content, file_path)
    sections = content.split(/^#/)
    
    sections.each_with_index do |section, index|
      concept_count = count_concepts(section)
      
      if concept_count > MAX_CONCEPTS_PER_SECTION
        add_violation("Too many concepts in section #{index}: #{concept_count}", file_path)
      end
    end
  end

  # § Helpers: Function extraction
  def extract_functions(content)
    functions = []
    current_function = nil
    
    content.lines.each_with_index do |line, index|
      if line.match?(/^\s*def\s+(\w+)/)
        current_function = {
          name: $1,
          start_line: index,
          lines: []
        }
      elsif line.match?(/^\s*end\s*$/) && current_function
        functions << current_function
        current_function = nil
      elsif current_function
        current_function[:lines] << line
      end
    end
    
    functions
  end

  # § Helpers: Variable name extraction
  def extract_variable_names(content)
    variable_names = []
    
    content.scan(/@(\w+)/) { |match| variable_names << match[0] }
    content.scan(/(\w+)\s*=/) { |match| variable_names << match[0] }
    
    variable_names.uniq
  end

  # § Helpers: Concept counting
  def count_concepts(text)
    # Simple heuristic: count unique nouns and technical terms
    words = text.downcase.split(/\W+/)
    technical_terms = words.select { |word| word.length > 4 }
    technical_terms.uniq.length
  end

  # § Reporting: Add validation violation
  def add_violation(message, file_path)
    @validation_results << {
      message: message,
      file: file_path,
      timestamp: Time.now
    }
  end

  # § Reporting: Generate compliance report
  def generate_compliance_report
    puts "\n" + "=" * 60
    puts "FRAMEWORK VALIDATION REPORT"
    puts "=" * 60
    
    puts "Total files validated: #{@total_files}"
    puts "Compliant files: #{@compliant_files}"
    puts "Violations found: #{@validation_results.length}"
    
    compliance_rate = (@compliant_files.to_f / @total_files * 100).round(2)
    puts "Compliance rate: #{compliance_rate}%"
    
    if @validation_results.any?
      puts "\nVIOLATIONS:"
      puts "-" * 40
      
      @validation_results.each do |violation|
        puts "#{violation[:file]}: #{violation[:message]}"
      end
    end
    
    puts "\nValidation completed in #{Time.now - @start_time} seconds"
    
    if compliance_rate >= 95.0
      puts "✅ FRAMEWORK COMPLIANCE: PASSED"
      exit 0
    else
      puts "❌ FRAMEWORK COMPLIANCE: FAILED"
      exit 1
    end
  end
end

# § Execution: Main validation entry point
if __FILE__ == $0
  validator = FrameworkValidator.new
  validator.validate_repository
end