#!/usr/bin/env ruby
# frozen_string_literal: true

require 'json'

# Master Framework v37.1.0 Validation Test
# Validates the comprehensive design intelligence integration

def validate_master_framework
  puts "🔍 Validating Master Framework v37.1.0 - Design Intelligence Integration..."
  
  # File paths
  master_file = '/home/runner/work/pub/pub/master.json'
  
  errors = []
  warnings = []
  
  begin
    # Load master framework
    master_config = JSON.parse(File.read(master_file))
    puts "✅ Master framework JSON loaded successfully"
    
    # Test 1: Meta information validation
    meta = master_config['meta']
    if meta['version'] == '37.1.0'
      puts "✅ Framework version correctly set to 37.1.0"
    else
      errors << "❌ Framework version incorrect: #{meta['version']}"
    end
    
    if meta['framework_name'] == 'Master Framework'
      puts "✅ Framework name correctly set"
    else
      errors << "❌ Framework name incorrect: #{meta['framework_name']}"
    end
    
    required_capabilities = ['autonomous_capabilities', 'design_intelligence_integrated', 'self_validated']
    required_capabilities.each do |capability|
      if meta[capability] == true
        puts "✅ #{capability} enabled"
      else
        errors << "❌ #{capability} not enabled"
      end
    end
    
    # Test 2: Design Intelligence Components
    design_intel = master_config['design_intelligence']
    if design_intel
      puts "✅ Design intelligence section present"
      
      # UX Psychology validation
      ux_psych = design_intel['deep_ux_psychology']
      if ux_psych && ux_psych['nielsen_norman_group_heuristics']
        heuristics_count = ux_psych['nielsen_norman_group_heuristics'].keys.length
        if heuristics_count >= 10
          puts "✅ Nielsen Norman Group heuristics complete (#{heuristics_count} heuristics)"
        else
          warnings << "⚠️ Nielsen Norman Group heuristics incomplete (#{heuristics_count}/10)"
        end
      else
        errors << "❌ Nielsen Norman Group heuristics missing"
      end
      
      # Typography validation
      typography = design_intel['swiss_international_typography']
      if typography && typography['helvetica_school_excellence']
        puts "✅ Swiss/International typography principles present"
      else
        errors << "❌ Swiss typography principles missing"
      end
      
      # Parametric architecture validation
      parametric = design_intel['parametric_architecture']
      if parametric && parametric['swarm_intelligence']
        puts "✅ Parametric architecture with swarm intelligence present"
      else
        errors << "❌ Parametric architecture missing"
      end
      
      # Cultural sensitivity validation
      cultural = design_intel['cultural_sensitivity']
      if cultural && cultural['global_accessibility']
        puts "✅ Cultural sensitivity and global accessibility present"
      else
        errors << "❌ Cultural sensitivity framework missing"
      end
      
    else
      errors << "❌ Design intelligence section missing"
    end
    
    # Test 3: Technical Excellence Components
    tech_excellence = master_config['technical_excellence']
    if tech_excellence
      puts "✅ Technical excellence section present"
      
      # Formatting rules validation
      if tech_excellence['formatting_rules'] && tech_excellence['formatting_rules']['indentation']['standard'] == '2_spaces'
        puts "✅ Formatting rules with 2-space indentation present"
      else
        errors << "❌ Formatting rules incomplete or incorrect"
      end
      
      # Tech stack specificity validation
      tech_stack = tech_excellence['tech_stack_specificity']
      if tech_stack && tech_stack['ruby_rails_patterns'] && tech_stack['openbsd_security']
        puts "✅ Ruby/Rails and OpenBSD tech stack rules present"
      else
        errors << "❌ Tech stack specificity incomplete"
      end
      
      # Error handling validation
      error_handling = tech_excellence['error_handling']
      if error_handling && error_handling['rollback_capabilities']
        puts "✅ Error handling with rollback capabilities present"
      else
        errors << "❌ Error handling framework incomplete"
      end
      
    else
      errors << "❌ Technical excellence section missing"
    end
    
    # Test 4: Autonomous Operation
    autonomous = master_config['autonomous_operation']
    if autonomous
      puts "✅ Autonomous operation section present"
      
      if autonomous['self_improving_capabilities']
        puts "✅ Self-improving capabilities defined"
      else
        errors << "❌ Self-improving capabilities missing"
      end
      
      if autonomous['adaptive_feedback_loops']
        puts "✅ Adaptive feedback loops defined"
      else
        errors << "❌ Adaptive feedback loops missing"
      end
      
      if autonomous['conflict_resolution_hierarchy']
        puts "✅ Conflict resolution hierarchy defined"
      else
        errors << "❌ Conflict resolution hierarchy missing"
      end
      
    else
      errors << "❌ Autonomous operation section missing"
    end
    
    # Test 5: Plugin Orchestration
    plugin_orch = master_config['plugin_orchestration']
    if plugin_orch && plugin_orch['module_loader']
      puts "✅ Plugin orchestration with module loader present"
      
      base_modules = plugin_orch['module_loader']['base_modules']
      if base_modules && base_modules.length >= 5
        puts "✅ Base modules referenced (#{base_modules.length} modules)"
      else
        warnings << "⚠️ Base modules incomplete"
      end
      
    else
      errors << "❌ Plugin orchestration missing"
    end
    
    # Test 6: Scientific Foundation
    scientific = master_config['scientific_foundation']
    if scientific && scientific['research_methodology']
      puts "✅ Scientific foundation with research methodology present"
    else
      errors << "❌ Scientific foundation missing"
    end
    
    # Test 7: File size and complexity validation
    file_size = File.size(master_file)
    if file_size > 25000  # ~25KB
      puts "✅ Master framework is comprehensive (#{file_size} bytes)"
    else
      warnings << "⚠️ Master framework may be incomplete (#{file_size} bytes)"
    end
    
    # Test 8: JSON structure validation
    required_top_level_sections = [
      'meta', 'design_intelligence', 'technical_excellence', 
      'autonomous_operation', 'plugin_orchestration', 
      'validation_framework', 'scientific_foundation'
    ]
    
    missing_sections = required_top_level_sections.reject { |section| master_config.key?(section) }
    if missing_sections.empty?
      puts "✅ All required top-level sections present"
    else
      errors << "❌ Missing top-level sections: #{missing_sections.join(', ')}"
    end
    
    # Summary
    puts "\n" + "="*60
    puts "MASTER FRAMEWORK VALIDATION SUMMARY"
    puts "="*60
    
    if errors.empty?
      puts "🎉 ALL VALIDATION TESTS PASSED!"
      puts "✅ Master Framework v37.1.0 successfully integrates comprehensive design intelligence"
      puts "✅ All technical excellence requirements met"
      puts "✅ Autonomous operation capabilities properly defined"
      puts "✅ Plugin orchestration system complete"
      puts "✅ Scientific foundation established"
      
      if warnings.any?
        puts "\n⚠️  WARNINGS (#{warnings.length}):"
        warnings.each { |warning| puts "   #{warning}" }
      end
      
      puts "\n📊 FRAMEWORK STATISTICS:"
      puts "   - Total size: #{file_size} bytes (~#{file_size/1024}KB)"
      puts "   - Design intelligence heuristics: #{ux_psych ? ux_psych['nielsen_norman_group_heuristics'].keys.length : 0}"
      puts "   - Top-level sections: #{master_config.keys.length}"
      puts "   - Compliance standards: #{meta['compliance'].length}"
      
      return true
    else
      puts "❌ VALIDATION FAILED (#{errors.length} errors, #{warnings.length} warnings)"
      puts "\nERRORS:"
      errors.each { |error| puts "   #{error}" }
      
      if warnings.any?
        puts "\nWARNINGS:"
        warnings.each { |warning| puts "   #{warning}" }
      end
      
      return false
    end
    
  rescue JSON::ParserError => e
    puts "❌ CRITICAL: Invalid JSON in master framework"
    puts "   Error: #{e.message}"
    return false
  rescue => e
    puts "❌ CRITICAL: Unexpected error during validation"
    puts "   Error: #{e.message}"
    puts "   Backtrace: #{e.backtrace.first(3).join("\n   ")}"
    return false
  end
end

# Run validation if script is executed directly
if __FILE__ == $0
  success = validate_master_framework
  exit(success ? 0 : 1)
end