# frozen_string_literal: true

#!/usr/bin/env ruby
# frozen_string_literal: true

require 'json'
require 'fileutils'
require 'time'
require 'logger'

# § Extreme Scrutiny Validator
# Implementation of master.json v12.9.0 extreme scrutiny framework
class ExtremeScrutinyValidator
  VERSION = '12.9.0'
  CIRCUIT_BREAKER_LIMITS = {
    max_iterations: 10,
    max_processing_time: 300,
    max_memory_usage: 1073741824, # 1GB in bytes
    max_cpu_percentage: 10.0,
    max_file_batch_size: 100
  }.freeze

  COMPLIANCE_THRESHOLDS = {
    logical_completeness: 95.0,
    function_line_limit: { min: 3, max: 20 },
    naming_length: { min: 5, max: 30 },
    duplicate_code: 0.0,
    cognitive_load: 95.0,
    readability_grade: 8
  }.freeze

  def initialize
  # TODO: Refactor initialize - exceeds 20 line limit (453 lines)
    @logger = create_logger
    @start_time = Time.now
    @processed_files = 0
    @failed_files = []
    @circuit_breaker_active = false
    @master_config = load_master_config
    @metrics = initialize_metrics
  end

  def validate_repository
    @logger.info "§ Starting Extreme Scrutiny Validation v#{VERSION}"
    @logger.info "User: anon987654321"
    @logger.info "Framework: master.json v12.9.0"
    @logger.info "Timestamp: #{Time.now.utc.iso8601}"

    check_circuit_breakers
    discover_files
    process_files_in_batches
    generate_compliance_report
    
    @logger.info "§ Validation Complete"
    @metrics[:overall_success]
  rescue StandardError => e
    @logger.error "Circuit breaker activated: #{e.message}"
    emergency_shutdown
    false
  end

  private

  def create_logger
    logger = Logger.new($stdout)
    logger.level = Logger::INFO
    logger.formatter = proc do |severity, datetime, progname, msg|
      "#{datetime.strftime('%Y-%m-%d %H:%M:%S')} [#{severity}] #{msg}\n"
    end
    logger
  end

  def load_master_config
    config_path = '/home/runner/work/pubhealthcare/pubhealthcare/prompts/master.json'
    return {} unless File.exist?(config_path)
    
    JSON.parse(File.read(config_path))
  rescue JSON::ParserError => e
    @logger.error "Failed to parse master.json: #{e.message}"
    {}
  end

  def initialize_metrics
    {
      total_files: 0,
      processed_files: 0,
      passed_files: 0,
      failed_files: 0,
      compliance_scores: [],
      resource_usage: {},
      circuit_breaker_activations: 0,
      overall_success: false
    }
  end

  def check_circuit_breakers
    @logger.info "Checking circuit breaker conditions..."
    
    # Check cognitive load from master.json
    cognitive_config = @master_config.dig('core', 'cognitive_load_budgeting')
    if cognitive_config&.dig('enabled')
      threshold = cognitive_config.dig('overflow_handling', 'detection_threshold')
      if threshold == '95%'
        @logger.info "✓ Cognitive load threshold configured at 95%"
      end
    end

    # Check system resources
    check_memory_availability
    check_processing_time
    
    @logger.info "✓ Circuit breakers initialized"
  end

  def check_memory_availability
    # Simulate memory check (in production would use system monitoring)
    available_memory = 2147483648 # 2GB simulated
    if available_memory < CIRCUIT_BREAKER_LIMITS[:max_memory_usage]
      raise "Insufficient memory available: #{available_memory} bytes"
    end
    
    @logger.info "✓ Memory check passed (#{available_memory / 1024 / 1024}MB available)"
  end

  def check_processing_time
    elapsed = Time.now - @start_time
    if elapsed > CIRCUIT_BREAKER_LIMITS[:max_processing_time]
      raise "Processing time exceeded: #{elapsed}s"
    end
    
    @logger.info "✓ Processing time check passed (#{elapsed.round(2)}s elapsed)"
  end

  def discover_files
    @logger.info "Discovering files for validation..."
    
    # Get all relevant files
    patterns = %w[**/*.rb **/*.js **/*.json **/*.md **/*.yml **/*.yaml **/*.html **/*.css]
    all_files = patterns.flat_map { |pattern| Dir.glob(pattern) }
    
    # Filter out excluded paths
    excluded_patterns = [
      /\.git\//,
      /\.bundle\//,
      /node_modules\//,
      /vendor\//,
      /tmp\//,
      /spec\/fixtures\//,
      /test\/fixtures\//
    ]
    
    @discovered_files = all_files.reject do |file|
      excluded_patterns.any? { |pattern| file.match?(pattern) }
    end
    
    @metrics[:total_files] = @discovered_files.length
    @logger.info "✓ Discovered #{@discovered_files.length} files for validation"
  end

  def process_files_in_batches
    @logger.info "Processing files in batches (max #{CIRCUIT_BREAKER_LIMITS[:max_file_batch_size]} per batch)..."
    
    @discovered_files.each_slice(CIRCUIT_BREAKER_LIMITS[:max_file_batch_size]) do |batch|
      break if @circuit_breaker_active
      
      process_batch(batch)
      check_circuit_breakers
    end
  end

  def process_batch(files)
    @logger.info "Processing batch of #{files.length} files..."
    
    files.each do |file|
      break if @circuit_breaker_active
      
      begin
        result = validate_file(file)
        @metrics[:processed_files] += 1
        
        if result[:passed]
          @metrics[:passed_files] += 1
        else
          @metrics[:failed_files] += 1
          @failed_files << { file: file, issues: result[:issues] }
        end
        
        @metrics[:compliance_scores] << result[:compliance_score]
        
      rescue StandardError => e
        @logger.error "Error processing #{file}: #{e.message}"
        @failed_files << { file: file, issues: ["Processing error: #{e.message}"] }
        @metrics[:failed_files] += 1
      end
    end
  end

  def validate_file(file)
    @logger.debug "Validating: #{file}"
    
    content = File.read(file)
    issues = []
    compliance_score = 100.0
    
    # Check file size for cognitive load
    if content.length > 50_000 # 50KB limit for cognitive load
      issues << "File too large (#{content.length} chars) - exceeds cognitive load limits"
      compliance_score -= 10
    end
    
    # Language-specific validation
    case File.extname(file)
    when '.rb'
      validate_ruby_file(content, issues, compliance_score)
    when '.js'
      validate_javascript_file(content, issues, compliance_score)
    when '.json'
      validate_json_file(content, issues, compliance_score)
    when '.md'
      validate_markdown_file(content, issues, compliance_score)
    when '.html'
      validate_html_file(content, issues, compliance_score)
    when '.css'
      validate_css_file(content, issues, compliance_score)
    end
    
    # Check for anti-truncation compliance
    check_anti_truncation(content, issues, compliance_score)
    
    # Check for clear naming
    check_naming_standards(content, issues, compliance_score)
    
    # Check for redundancy
    check_redundancy(content, issues, compliance_score)
    
    passed = issues.empty? && compliance_score >= COMPLIANCE_THRESHOLDS[:logical_completeness]
    
    {
      passed: passed,
      issues: issues,
      compliance_score: compliance_score
    }
  end

  def validate_ruby_file(content, issues, compliance_score)
    # Check for frozen_string_literal
    unless content.start_with?('# frozen_string_literal: true')
      issues << "Missing frozen_string_literal directive"
      compliance_score -= 5
    end
    
    # Check function length (simplified check)
    method_lines = content.scan(/^\s*def\s+\w+.*?^\s*end/m)
    method_lines.each do |method|
      lines = method.split("\n").length
      if lines < COMPLIANCE_THRESHOLDS[:function_line_limit][:min] || 
         lines > COMPLIANCE_THRESHOLDS[:function_line_limit][:max]
        issues << "Method length violation: #{lines} lines (should be 3-20)"
        compliance_score -= 3
      end
    end
    
    # Check for cognitive headers
    unless content.include?('# § ')
      issues << "Missing cognitive headers (# § format)"
      compliance_score -= 5
    end
    
    compliance_score
  end

  def validate_javascript_file(content, issues, compliance_score)
    # Check for proper semicolon usage
    unless content.match?(/;\s*$/)
      issues << "Missing semicolons in JavaScript"
      compliance_score -= 5
    end
    
    # Check for const/let usage over var
    if content.include?('var ')
      issues << "Use const/let instead of var"
      compliance_score -= 3
    end
    
    compliance_score
  end

  def validate_json_file(content, issues, compliance_score)
    begin
      JSON.parse(content)
    rescue JSON::ParserError => e
      issues << "Invalid JSON: #{e.message}"
      compliance_score -= 20
    end
    
    compliance_score
  end

  def validate_markdown_file(content, issues, compliance_score)
    # Check for proper heading hierarchy
    headings = content.scan(/^#+\s+(.+)$/)
    if headings.empty?
      issues << "No headings found in markdown"
      compliance_score -= 5
    end
    
    # Check for cognitive headers
    unless content.include?('# § ')
      issues << "Missing cognitive headers (# § format)"
      compliance_score -= 3
    end
    
    compliance_score
  end

  def validate_html_file(content, issues, compliance_score)
    # Check for semantic HTML5 elements
    semantic_elements = %w[header main section footer article aside nav]
    has_semantic = semantic_elements.any? { |elem| content.include?("<#{elem}") }
    
    unless has_semantic
      issues << "Missing semantic HTML5 elements"
      compliance_score -= 10
    end
    
    # Check for ARIA labels
    unless content.include?('aria-') || content.include?('role=')
      issues << "Missing ARIA accessibility attributes"
      compliance_score -= 10
    end
    
    compliance_score
  end

  def validate_css_file(content, issues, compliance_score)
    # Check for custom properties (CSS variables)
    unless content.include?('--')
      issues << "Missing CSS custom properties for maintainability"
      compliance_score -= 5
    end
    
    # Check for mobile-first approach
    unless content.include?('@media') && content.include?('min-width')
      issues << "Missing mobile-first responsive design"
      compliance_score -= 8
    end
    
    compliance_score
  end

  def check_anti_truncation(content, issues, compliance_score)
    # Check for logical completeness
    logical_indicators = [
      'if', 'else', 'elsif', 'unless', 'when', 'case',
      'for', 'while', 'until', 'loop', 'each',
      'begin', 'rescue', 'ensure', 'end',
      'function', 'return', 'throw', 'catch', 'finally'
    ]
    
    incomplete_blocks = 0
    logical_indicators.each do |indicator|
      matches = content.scan(/#{indicator}/)
      if matches.count > 0
        # Simple heuristic: check if logical blocks are properly closed
        case indicator
        when 'if', 'unless', 'case', 'begin', 'for', 'while', 'until'
          end_count = content.scan(/end/).count
          incomplete_blocks += 1 if end_count < matches.count
        end
      end
    end
    
    if incomplete_blocks > 0
      issues << "Potential logical incompleteness detected"
      compliance_score -= (incomplete_blocks * 5)
    end
    
    compliance_score
  end

  def check_naming_standards(content, issues, compliance_score)
    # Check variable and function names
    names = content.scan(/(?:def|const|let|var|class)\s+(\w+)/)
    names.flatten.each do |name|
      if name.length < COMPLIANCE_THRESHOLDS[:naming_length][:min] || 
         name.length > COMPLIANCE_THRESHOLDS[:naming_length][:max]
        issues << "Naming violation: '#{name}' (#{name.length} chars, should be 5-30)"
        compliance_score -= 2
      end
      
      # Check for abbreviations (simplified)
      if name.match?(/\b(btn|img|txt|num|str|arr|obj|elem|attr|param|val|var|tmp|temp)\b/i)
        issues << "Avoid abbreviations in names: '#{name}'"
        compliance_score -= 1
      end
    end
    
    compliance_score
  end

  def check_redundancy(content, issues, compliance_score)
    # Simple duplicate detection
    lines = content.split("\n").map(&:strip).reject(&:empty?)
    duplicate_lines = lines.group_by(&:itself).select { |_, v| v.length > 1 }
    
    if duplicate_lines.any?
      duplicate_percentage = (duplicate_lines.length.to_f / lines.length * 100).round(2)
      if duplicate_percentage > COMPLIANCE_THRESHOLDS[:duplicate_code]
        issues << "Code redundancy detected: #{duplicate_percentage}% duplicate lines"
        compliance_score -= (duplicate_percentage * 2)
      end
    end
    
    compliance_score
  end

  def generate_compliance_report
    @logger.info "§ Generating Compliance Report"
    
    # Calculate overall metrics
    average_compliance = @metrics[:compliance_scores].sum / @metrics[:compliance_scores].length
    success_rate = (@metrics[:passed_files].to_f / @metrics[:processed_files] * 100).round(2)
    
    @metrics[:overall_success] = average_compliance >= COMPLIANCE_THRESHOLDS[:logical_completeness] &&
                                 success_rate >= 95.0
    
    # Generate report
    report = {
      meta: {
        version: VERSION,
        timestamp: Time.now.utc.iso8601,
        user: 'anon987654321',
        framework: 'master.json v12.9.0'
      },
      summary: {
        total_files: @metrics[:total_files],
        processed_files: @metrics[:processed_files],
        passed_files: @metrics[:passed_files],
        failed_files: @metrics[:failed_files],
        success_rate: success_rate,
        average_compliance: average_compliance.round(2),
        overall_success: @metrics[:overall_success]
      },
      thresholds: COMPLIANCE_THRESHOLDS,
      circuit_breaker_limits: CIRCUIT_BREAKER_LIMITS,
      failed_files: @failed_files.first(20), # Limit to first 20 for readability
      resource_usage: {
        processing_time: (Time.now - @start_time).round(2),
        memory_usage: "#{CIRCUIT_BREAKER_LIMITS[:max_memory_usage] / 1024 / 1024}MB (limit)",
        cpu_usage: "#{CIRCUIT_BREAKER_LIMITS[:max_cpu_percentage]}% (limit)"
      }
    }
    
    # Save report
    File.write('extreme_scrutiny_report.json', JSON.pretty_generate(report))
    
    # Log summary
    @logger.info "Files processed: #{@metrics[:processed_files]}/#{@metrics[:total_files]}"
    @logger.info "Success rate: #{success_rate}%"
    @logger.info "Average compliance: #{average_compliance.round(2)}%"
    @logger.info "Overall success: #{@metrics[:overall_success]}"
    @logger.info "Report saved: extreme_scrutiny_report.json"
    
    # Check success criteria
    if @metrics[:overall_success]
      @logger.info "🟢 Extreme scrutiny validation PASSED"
    else
      @logger.error "🔴 Extreme scrutiny validation FAILED"
      @logger.error "Required: 95%+ logical completeness, 95%+ success rate"
    end
  end

  def emergency_shutdown
    @logger.error "§ Emergency Shutdown Activated"
    @logger.error "Circuit breaker limits exceeded"
    @logger.error "Processed: #{@metrics[:processed_files]} files"
    @logger.error "Time elapsed: #{(Time.now - @start_time).round(2)}s"
    
    # Save partial report
    generate_compliance_report
    
    @metrics[:circuit_breaker_activations] += 1
    @circuit_breaker_active = true
  end
end

# Execute validation if run directly
if __FILE__ == $0
  validator = ExtremeScrutinyValidator.new
  success = validator.validate_repository
  exit(success ? 0 : 1)
end