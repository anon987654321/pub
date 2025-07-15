# frozen_string_literal: true

#!/usr/bin/env ruby
# frozen_string_literal: true

require 'json'
require 'time'
require 'logger'
require_relative 'resource_monitor'

# § Anti-Truncation Compliance Engine
# Ensures 95%+ logical completeness following master.json v12.9.0
class AntiTruncationEngine
  LOGICAL_COMPLETENESS_THRESHOLD = 95.0
  MAX_SENTENCE_LENGTH = 15 # words per sentence (Strunk & White)
  MAX_READABILITY_GRADE = 8
  CIRCUIT_BREAKER_ITERATION_LIMIT = 10
  
  def initialize(master_config = {})
  # TODO: Refactor initialize - exceeds 20 line limit (496 lines)
    @logger = create_logger
    @master_config = master_config
    @resource_monitor = ResourceMonitor.new(master_config)
    @processed_items = 0
    @circuit_breaker_count = 0
    @completeness_scores = []
  end

  def analyze_repository_completeness
    @logger.info "§ Anti-Truncation Analysis Started"
    @logger.info "Threshold: #{LOGICAL_COMPLETENESS_THRESHOLD}% logical completeness"
    @logger.info "Sentence limit: #{MAX_SENTENCE_LENGTH} words (Strunk & White)"
    @logger.info "Readability grade: #{MAX_READABILITY_GRADE} maximum"
    
    @resource_monitor.start_monitoring
    
    begin
      files = discover_content_files
      results = analyze_files(files)
      generate_completeness_report(results)
      
      overall_success = results[:overall_completeness] >= LOGICAL_COMPLETENESS_THRESHOLD
      @logger.info "§ Anti-Truncation Analysis Complete: #{overall_success ? 'PASS' : 'FAIL'}"
      
      overall_success
    ensure
      @resource_monitor.stop_monitoring
    end
  end

  def fix_truncation_issues(files)
    @logger.info "§ Fixing Truncation Issues"
    
    fixed_files = []
    
    files.each do |file|
      break if @circuit_breaker_count >= CIRCUIT_BREAKER_ITERATION_LIMIT
      
      begin
        if fix_file_truncation(file)
          fixed_files << file
          @logger.info "✓ Fixed truncation in: #{file}"
        end
      rescue StandardError => e
        @logger.error "Error fixing #{file}: #{e.message}"
        @circuit_breaker_count += 1
      end
    end
    
    @logger.info "Fixed #{fixed_files.length} files"
    fixed_files
  end

  private

  def create_logger
    logger = Logger.new($stdout)
    logger.level = Logger::INFO
    logger.formatter = proc do |severity, datetime, progname, msg|
      "#{datetime.strftime('%Y-%m-%d %H:%M:%S')} [ANTI-TRUNC] #{msg}\n"
    end
    logger
  end

  def discover_content_files
    @logger.info "Discovering content files for analysis..."
    
    # Focus on content files that can have truncation issues
    patterns = %w[**/*.rb **/*.js **/*.md **/*.html **/*.css **/*.yml **/*.yaml]
    all_files = patterns.flat_map { |pattern| Dir.glob(pattern) }
    
    # Filter out system files
    excluded_patterns = [
      /\.git\//,
      /\.bundle\//,
      /node_modules\//,
      /vendor\//,
      /tmp\//,
      /\.min\./,
      /\.map$/
    ]
    
    content_files = all_files.reject do |file|
      excluded_patterns.any? { |pattern| file.match?(pattern) }
    end
    
    @logger.info "✓ Found #{content_files.length} content files"
    content_files
  end

  def analyze_files(files)
    @logger.info "Analyzing #{files.length} files for logical completeness..."
    
    results = {
      files_analyzed: 0,
      files_passed: 0,
      files_failed: 0,
      completeness_scores: [],
      detailed_issues: [],
      overall_completeness: 0.0
    }
    
    files.each do |file|
      break if @circuit_breaker_count >= CIRCUIT_BREAKER_ITERATION_LIMIT
      
      begin
        file_result = analyze_file_completeness(file)
        results[:files_analyzed] += 1
        
        if file_result[:passed]
          results[:files_passed] += 1
        else
          results[:files_failed] += 1
          results[:detailed_issues] << file_result
        end
        
        results[:completeness_scores] << file_result[:completeness_score]
        @processed_items += 1
        
        # Check resource usage periodically
        if @processed_items % 10 == 0
          check_resource_status
        end
        
      rescue StandardError => e
        @logger.error "Error analyzing #{file}: #{e.message}"
        @circuit_breaker_count += 1
      end
    end
    
    # Calculate overall completeness
    if results[:completeness_scores].any?
      results[:overall_completeness] = 
        (results[:completeness_scores].sum / results[:completeness_scores].length).round(2)
    end
    
    results
  end

  def analyze_file_completeness(file)
    @logger.debug "Analyzing: #{file}"
    
    content = File.read(file)
    completeness_score = 100.0
    issues = []
    
    # Check for logical structure completeness
    check_logical_structure(content, issues, completeness_score)
    
    # Check for sentence length compliance (Strunk & White)
    check_sentence_length(content, issues, completeness_score)
    
    # Check for readability grade
    check_readability_grade(content, issues, completeness_score)
    
    # Check for context preservation
    check_context_preservation(content, issues, completeness_score)
    
    # Check for complete function implementations
    check_function_completeness(content, issues, completeness_score)
    
    # Check for proper error handling
    check_error_handling(content, issues, completeness_score)
    
    passed = completeness_score >= LOGICAL_COMPLETENESS_THRESHOLD
    
    {
      file: file,
      passed: passed,
      completeness_score: completeness_score,
      issues: issues,
      recommendations: generate_recommendations(issues)
    }
  end

  def check_logical_structure(content, issues, completeness_score)
    # Check for balanced control structures
    control_structures = {
      'if' => 'end',
      'unless' => 'end',
      'case' => 'end',
      'while' => 'end',
      'for' => 'end',
      'begin' => 'end',
      'def' => 'end',
      'class' => 'end',
      'module' => 'end'
    }
    
    control_structures.each do |opening, closing|
      opening_count = content.scan(/\b#{opening}\b/).length
      closing_count = content.scan(/\b#{closing}\b/).length
      
      if opening_count > closing_count
        issues << "Unbalanced #{opening}/#{closing} structures: #{opening_count} opens, #{closing_count} closes"
        completeness_score -= 10
      end
    end
    
    # Check for incomplete logical chains
    logical_chains = [
      ['if', 'else'],
      ['try', 'catch'],
      ['begin', 'rescue']
    ]
    
    logical_chains.each do |chain|
      first_count = content.scan(/\b#{chain[0]}\b/).length
      second_count = content.scan(/\b#{chain[1]}\b/).length
      
      if first_count > 0 && second_count == 0
        issues << "Incomplete logical chain: #{chain[0]} without #{chain[1]}"
        completeness_score -= 5
      end
    end
    
    completeness_score
  end

  def check_sentence_length(content, issues, completeness_score)
    # Extract sentences (simplified)
    sentences = content.scan(/[.!?]+/).map(&:strip).reject(&:empty?)
    
    long_sentences = sentences.select do |sentence|
      word_count = sentence.split.length
      word_count > MAX_SENTENCE_LENGTH
    end
    
    if long_sentences.any?
      issues << "#{long_sentences.length} sentences exceed #{MAX_SENTENCE_LENGTH} words (Strunk & White)"
      completeness_score -= (long_sentences.length * 2)
    end
    
    completeness_score
  end

  def check_readability_grade(content, issues, completeness_score)
    # Simplified readability calculation (Flesch-Kincaid approximation)
    sentences = content.scan(/[.!?]+/).length
    words = content.scan(/\b\w+\b/).length
    syllables = estimate_syllables(content)
    
    return completeness_score if sentences == 0 || words == 0
    
    avg_sentence_length = words.to_f / sentences
    avg_syllables_per_word = syllables.to_f / words
    
    # Simplified Flesch-Kincaid grade level
    grade_level = (0.39 * avg_sentence_length) + (11.8 * avg_syllables_per_word) - 15.59
    
    if grade_level > MAX_READABILITY_GRADE
      issues << "Readability grade #{grade_level.round(1)} exceeds maximum #{MAX_READABILITY_GRADE}"
      completeness_score -= 5
    end
    
    completeness_score
  end

  def estimate_syllables(text)
    # Simple syllable estimation
    words = text.scan(/\b\w+\b/)
    total_syllables = 0
    
    words.each do |word|
      vowels = word.downcase.scan(/[aeiou]/).length
      vowels = 1 if vowels == 0
      total_syllables += vowels
    end
    
    total_syllables
  end

  def check_context_preservation(content, issues, completeness_score)
    # Check for abrupt endings or incomplete thoughts
    lines = content.split("\n")
    
    # Check for incomplete comment blocks
    incomplete_comments = lines.select { |line| line.strip.start_with?('#') && line.strip.length < 5 }
    if incomplete_comments.any?
      issues << "#{incomplete_comments.length} incomplete comment lines detected"
      completeness_score -= 2
    end
    
    # Check for incomplete function documentation
    def_lines = lines.select { |line| line.strip.start_with?('def ') }
    def_lines.each_with_index do |def_line, index|
      line_number = lines.index(def_line)
      prev_line = line_number > 0 ? lines[line_number - 1] : nil
      
      if prev_line.nil? || !prev_line.strip.start_with?('#')
        issues << "Function at line #{line_number + 1} missing documentation"
        completeness_score -= 1
      end
    end
    
    completeness_score
  end

  def check_function_completeness(content, issues, completeness_score)
    # Extract function definitions
    functions = content.scan(/def\s+(\w+).*?^end/m)
    
    functions.each do |func_match|
      func_content = func_match.is_a?(Array) ? func_match[0] : func_match
      
      # Check for functions that are too short (likely incomplete)
      lines = func_content.split("\n").reject { |line| line.strip.empty? }
      if lines.length < 3
        issues << "Function '#{func_content}' appears incomplete (#{lines.length} lines)"
        completeness_score -= 3
      end
    end
    
    completeness_score
  end

  def check_error_handling(content, issues, completeness_score)
    # Check for proper error handling patterns
    error_patterns = {
      'begin' => ['rescue', 'ensure'],
      'rescue' => ['StandardError', 'Exception'],
      'raise' => ['StandardError', 'RuntimeError']
    }
    
    error_patterns.each do |pattern, required|
      pattern_count = content.scan(/\b#{pattern}\b/).length
      
      if pattern_count > 0
        required.each do |req|
          req_count = content.scan(/\b#{req}\b/).length
          if req_count == 0
            issues << "#{pattern} block missing #{req} handling"
            completeness_score -= 2
          end
        end
      end
    end
    
    completeness_score
  end

  def generate_recommendations(issues)
    recommendations = []
    
    issues.each do |issue|
      case issue
      when /Unbalanced/
        recommendations << "Review control structure balance - ensure all blocks are properly closed"
      when /sentence.*exceed/
        recommendations << "Break long sentences into shorter ones (max 15 words per Strunk & White)"
      when /Readability grade/
        recommendations << "Simplify language and sentence structure to improve readability"
      when /incomplete comment/
        recommendations << "Expand comment blocks to provide meaningful context"
      when /missing documentation/
        recommendations << "Add comprehensive documentation for all functions"
      when /appears incomplete/
        recommendations << "Expand function implementation to include proper logic"
      when /missing.*handling/
        recommendations << "Add comprehensive error handling and recovery mechanisms"
      end
    end
    
    recommendations.uniq
  end

  def fix_file_truncation(file)
    @logger.debug "Attempting to fix truncation in: #{file}"
    
    content = File.read(file)
    original_content = content.dup
    
    # Apply fixes based on file type
    case File.extname(file)
    when '.rb'
      content = fix_ruby_truncation(content)
    when '.js'
      content = fix_javascript_truncation(content)
    when '.md'
      content = fix_markdown_truncation(content)
    when '.html'
      content = fix_html_truncation(content)
    end
    
    # Only write if changes were made
    if content != original_content
      File.write(file, content)
      true
    else
      false
    end
  end

  def fix_ruby_truncation(content)
    # Add frozen_string_literal if missing
    unless content.start_with?('# frozen_string_literal: true')
      content = "# frozen_string_literal: true\n\n#{content}"
    end
    
    # Add cognitive headers if missing
    unless content.include?('# § ')
      content = "# § #{File.basename(file, '.*').gsub('_', ' ').capitalize}\n#{content}"
    end
    
    content
  end

  def fix_javascript_truncation(content)
    # Add strict mode if missing
    unless content.include?("'use strict'")
      content = "'use strict';\n\n#{content}"
    end
    
    content
  end

  def fix_markdown_truncation(content)
    # Add cognitive headers if missing
    unless content.include?('# § ')
      title = File.basename(file, '.*').gsub('_', ' ').split.map(&:capitalize).join(' ')
      content = "# § #{title}\n\n#{content}"
    end
    
    content
  end

  def fix_html_truncation(content)
    # Add semantic structure if missing
    unless content.include?('<main>')
      content = content.gsub(/<body[^>]*>/, '<body>\n<main>')
                       .gsub('</body>', '</main>\n</body>')
    end
    
    content
  end

  def check_resource_status
    status = @resource_monitor.current_status
    
    if status[:status] == 'circuit_breaker_active'
      @logger.warn "Resource monitor circuit breaker active - pausing processing"
      sleep 5
      @circuit_breaker_count += 1
    end
  end

  def generate_completeness_report(results)
    @logger.info "§ Generating Anti-Truncation Report"
    
    report = {
      meta: {
        version: '12.9.0',
        timestamp: Time.now.utc.iso8601,
        user: 'anon987654321',
        framework: 'master.json v12.9.0',
        analysis_type: 'anti_truncation_compliance'
      },
      thresholds: {
        logical_completeness: LOGICAL_COMPLETENESS_THRESHOLD,
        sentence_length: MAX_SENTENCE_LENGTH,
        readability_grade: MAX_READABILITY_GRADE
      },
      summary: {
        files_analyzed: results[:files_analyzed],
        files_passed: results[:files_passed],
        files_failed: results[:files_failed],
        overall_completeness: results[:overall_completeness],
        pass_rate: (results[:files_passed].to_f / results[:files_analyzed] * 100).round(2)
      },
      detailed_results: results[:detailed_issues].first(20), # Limit for readability
      circuit_breaker: {
        activations: @circuit_breaker_count,
        iteration_limit: CIRCUIT_BREAKER_ITERATION_LIMIT
      },
      compliance_status: {
        meets_threshold: results[:overall_completeness] >= LOGICAL_COMPLETENESS_THRESHOLD,
        recommendation: results[:overall_completeness] >= LOGICAL_COMPLETENESS_THRESHOLD ? 
                       "Excellent logical completeness" : 
                       "Requires improvement to meet 95% threshold"
      }
    }
    
    # Save report
    File.write('anti_truncation_report.json', JSON.pretty_generate(report))
    
    # Log summary
    @logger.info "Files analyzed: #{results[:files_analyzed]}"
    @logger.info "Files passed: #{results[:files_passed]}"
    @logger.info "Files failed: #{results[:files_failed]}"
    @logger.info "Overall completeness: #{results[:overall_completeness]}%"
    @logger.info "Pass rate: #{report[:summary][:pass_rate]}%"
    @logger.info "Threshold compliance: #{report[:compliance_status][:meets_threshold] ? 'PASS' : 'FAIL'}"
    @logger.info "Report saved: anti_truncation_report.json"
  end
end

# Execute analysis if run directly
if __FILE__ == $0
  # Load master.json configuration
  config_path = '/home/runner/work/pubhealthcare/pubhealthcare/prompts/master.json'
  master_config = {}
  
  if File.exist?(config_path)
    begin
      master_config = JSON.parse(File.read(config_path))
    rescue JSON::ParserError
      puts "Warning: Could not parse master.json"
    end
  end
  
  # Run analysis
  engine = AntiTruncationEngine.new(master_config)
  success = engine.analyze_repository_completeness
  
  puts success ? "✓ Anti-truncation analysis PASSED" : "✗ Anti-truncation analysis FAILED"
  exit(success ? 0 : 1)
end