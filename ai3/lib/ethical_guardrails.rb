# frozen_string_literal: true

# ethical_guardrails.rb - Content filtering and safety checks

class EthicalGuardrails
  attr_reader :config, :violation_log

  def initialize(config = {})
    @config = default_config.merge(config)
    @violation_log = []
    @patterns = load_filter_patterns
  end

  # Main content filtering method
  def filter_content(content, context = {})
    violations = []
    
    # Check for various violation types
    violations.concat(check_harmful_content(content))
    violations.concat(check_personal_info(content))
    violations.concat(check_inappropriate_content(content))
    violations.concat(check_copyright_violations(content))
    violations.concat(check_misinformation(content))
    
    # Log violations
    if violations.any?
      log_violation(content, violations, context)
    end
    
    {
      allowed: violations.empty?,
      violations: violations,
      filtered_content: violations.empty? ? content : filter_violations(content, violations),
      severity: calculate_severity(violations)
    }
  end

  # Check if a query is safe to process
  def safe_query?(query, context = {})
    result = filter_content(query, context.merge(type: :query))
    result[:allowed] && result[:severity] < @config[:max_query_severity]
  end

  # Check if response content is safe to return
  def safe_response?(response, context = {})
    result = filter_content(response, context.merge(type: :response))
    result[:allowed] && result[:severity] < @config[:max_response_severity]
  end

  # Get violation statistics
  def violation_stats
    return { total: 0 } if @violation_log.empty?
    
    by_type = @violation_log.group_by { |v| v[:primary_violation] }
    by_severity = @violation_log.group_by { |v| v[:severity] }
    
    {
      total: @violation_log.size,
      by_type: by_type.transform_values(&:size),
      by_severity: by_severity.transform_values(&:size),
      recent_24h: @violation_log.count { |v| v[:timestamp] > Time.now - 86400 }
    }
  end

  private

  def default_config
    {
      max_query_severity: 3,
      max_response_severity: 2,
      enable_personal_info_filter: true,
      enable_harmful_content_filter: true,
      enable_copyright_filter: true,
      enable_misinformation_filter: false, # Too complex for basic implementation
      log_violations: true
    }
  end

  def load_filter_patterns
    {
      harmful_keywords: [
        'violence', 'harm', 'hurt', 'kill', 'destroy', 'bomb', 'weapon',
        'hate', 'discrimination', 'harassment', 'threat', 'abuse'
      ],
      personal_info: [
        /\b\d{3}-\d{2}-\d{4}\b/, # SSN pattern
        /\b\d{4}[- ]?\d{4}[- ]?\d{4}[- ]?\d{4}\b/, # Credit card pattern
        /\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b/ # Email pattern
      ],
      inappropriate: [
        'explicit', 'sexual', 'nsfw', 'adult', 'pornographic'
      ],
      copyright: [
        'copyright', '©', 'all rights reserved', 'proprietary',
        'confidential', 'trade secret'
      ]
    }
  end

  def check_harmful_content(content)
    return [] unless @config[:enable_harmful_content_filter]
    
    violations = []
    lower_content = content.downcase
    
    @patterns[:harmful_keywords].each do |keyword|
      if lower_content.include?(keyword)
        violations << {
          type: :harmful_content,
          keyword: keyword,
          severity: 4,
          message: "Contains potentially harmful keyword: #{keyword}"
        }
      end
    end
    
    violations
  end

  def check_personal_info(content)
    return [] unless @config[:enable_personal_info_filter]
    
    violations = []
    
    @patterns[:personal_info].each do |pattern|
      if content.match?(pattern)
        violations << {
          type: :personal_info,
          pattern: pattern.inspect,
          severity: 3,
          message: "Contains potentially sensitive personal information"
        }
      end
    end
    
    violations
  end

  def check_inappropriate_content(content)
    violations = []
    lower_content = content.downcase
    
    @patterns[:inappropriate].each do |keyword|
      if lower_content.include?(keyword)
        violations << {
          type: :inappropriate,
          keyword: keyword,
          severity: 2,
          message: "Contains inappropriate content keyword: #{keyword}"
        }
      end
    end
    
    violations
  end

  def check_copyright_violations(content)
    return [] unless @config[:enable_copyright_filter]
    
    violations = []
    lower_content = content.downcase
    
    @patterns[:copyright].each do |keyword|
      if lower_content.include?(keyword)
        violations << {
          type: :copyright,
          keyword: keyword,
          severity: 2,
          message: "May contain copyrighted material: #{keyword}"
        }
      end
    end
    
    violations
  end

  def check_misinformation(content)
    return [] unless @config[:enable_misinformation_filter]
    
    # This would require sophisticated ML models in a real implementation
    # For now, just a placeholder
    []
  end

  def calculate_severity(violations)
    return 0 if violations.empty?
    violations.map { |v| v[:severity] }.max
  end

  def filter_violations(content, violations)
    filtered = content.dup
    
    violations.each do |violation|
      case violation[:type]
      when :personal_info
        # Replace personal info with placeholder
        filtered = filtered.gsub(@patterns[:personal_info].find { |p| content.match?(p) }, '[REDACTED]')
      when :harmful_content, :inappropriate
        # Add warning
        filtered = "[CONTENT FILTERED: #{violation[:message]}]\n\n#{filtered}"
      when :copyright
        # Add disclaimer
        filtered = "#{filtered}\n\n[Note: Content may contain copyrighted material]"
      end
    end
    
    filtered
  end

  def log_violation(content, violations, context)
    return unless @config[:log_violations]
    
    @violation_log << {
      timestamp: Time.now,
      content_preview: content[0..100],
      violations: violations,
      primary_violation: violations.first[:type],
      severity: calculate_severity(violations),
      context: context
    }
    
    # Keep log size manageable
    @violation_log.shift if @violation_log.size > 1000
  end
end