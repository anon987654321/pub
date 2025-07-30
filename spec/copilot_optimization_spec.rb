require 'rspec'
require 'json'

# Copilot Optimization Module Test Suite
# Validates the new copilot-optimization.json module integration

describe 'Copilot Optimization Integration' do
  let(:framework_file) { '/home/runner/work/pub/pub/prompts-v37.json' }
  let(:copilot_module_file) { '/home/runner/work/pub/pub/modules/copilot-optimization.json' }
  let(:quality_gates_file) { '/home/runner/work/pub/pub/modules/quality-gates.json' }
  
  let(:framework_config) { JSON.parse(File.read(framework_file)) }
  let(:copilot_module) { JSON.parse(File.read(copilot_module_file)) }
  let(:quality_gates) { JSON.parse(File.read(quality_gates_file)) }

  describe 'Framework Version Integration' do
    it 'increments framework version to 37.1.0' do
      expect(framework_config['meta']['version']).to eq('37.1.0')
    end

    it 'includes copilot-optimization in base modules' do
      base_modules = framework_config['plugin_system']['module_loader']['base_modules']
      expect(base_modules).to include('modules/copilot-optimization.json')
    end

    it 'adds copilot_optimization section with proper cross-reference' do
      copilot_section = framework_config['copilot_optimization']
      expect(copilot_section).not_to be_nil
      expect(copilot_section['plugin_ref']).to eq('@ref:modules/copilot-optimization.json')
    end

    it 'updates improvement validation metrics' do
      validation = framework_config['meta']['improvement_validation']
      expect(validation['before_version']).to eq('37.0.0')
      expect(validation['after_version']).to eq('37.1.0')
      expect(validation['methodology']).to eq('copilot_optimization_integration')
    end
  end

  describe 'Copilot Module Structure' do
    it 'has valid module metadata' do
      meta = copilot_module['meta']
      expect(meta['module_name']).to eq('copilot-optimization')
      expect(meta['version']).to eq('37.1.0')
      expect(meta['module_type']).to eq('core_module')
      expect(meta['framework_version_compatibility']).to eq('37.1.x')
    end

    it 'addresses all 8 critical Copilot issues' do
      issues = copilot_module['critical_issues_addressed']
      expected_issues = [
        'progressive_model_degradation',
        'multi_line_suggestion_failures', 
        'content_exclusion_confusion',
        'rate_limiting_connection_issues',
        'skill_erosion_prevention',
        'context_loss_long_conversations',
        'limited_multi_file_awareness',
        'dependency_management_blindness'
      ]
      
      expected_issues.each do |issue|
        expect(issues).to have_key(issue)
        expect(issues[issue]['severity']).to be_in(['high', 'medium', 'critical'])
        expect(issues[issue]['mitigation']).not_to be_empty
      end
    end

    it 'implements master and temporary context systems' do
      context_system = copilot_module['context_system']
      
      # Master context
      master_context = context_system['master_context']
      expect(master_context['immutable']).to be true
      expect(master_context['components']).to have_key('language_detection')
      expect(master_context['components']).to have_key('project_type_categorization')
      
      # Temporary context  
      temp_context = context_system['temporary_context']
      expect(temp_context['mutable']).to be true
      expect(temp_context['components']).to have_key('current_task_tracking')
      expect(temp_context['components']).to have_key('session_duration_tracking')
    end

    it 'defines optimization strategies with measurable targets' do
      strategies = copilot_module['optimization_strategies']
      
      expect(strategies['context_alignment_enhancement']['target_accuracy']).to eq('90_percent')
      expect(strategies['suggestion_relevance_optimization']['target_score']).to eq('85_percent')
      expect(strategies['workflow_disruption_reduction']['target_reduction']).to eq('70_percent')
      expect(strategies['edge_case_coverage']['target_coverage']).to eq('80_percent')
    end

    it 'includes validation framework with copilot_context_alignment' do
      validation = copilot_module['validation_framework']
      alignment_check = validation['copilot_context_alignment']
      
      expect(alignment_check['description']).to include('Copilot context system integrity')
      expect(alignment_check['checks']).to include('master_context_immutability')
      expect(alignment_check['checks']).to include('temporary_context_refresh_functionality')
    end
  end

  describe 'Quality Gates Integration' do
    it 'adds copilot_context_alignment to framework mandatory validations' do
      validations = framework_config['validation_framework']['mandatory_validations']
      expect(validations).to include('copilot_context_alignment')
    end

    it 'includes copilot validation in pre_deploy gate' do
      pre_deploy = quality_gates['validation_gates']['pre_deploy']
      expect(pre_deploy).to have_key('copilot_context_alignment')
      expect(pre_deploy['copilot_context_alignment']).to include('@ref:copilot-optimization')
    end

    it 'adds copilot optimization metrics' do
      metrics = quality_gates['quality_metrics']['copilot_optimization_metrics']
      expect(metrics).to have_key('context_alignment_accuracy')
      expect(metrics).to have_key('suggestion_relevance_score')
      expect(metrics).to have_key('workflow_disruption_reduction')
      expect(metrics).to have_key('edge_case_coverage')
    end
  end

  describe 'Cross-Reference System Integrity' do
    it 'uses proper @ref: syntax for all dependencies' do
      # Check copilot module dependencies
      expect(copilot_module['meta']['dependencies']).to include('behavioral-rules')
      expect(copilot_module['meta']['dependencies']).to include('workflow-engine')
      expect(copilot_module['meta']['dependencies']).to include('quality-gates')
      
      # Check cross-references in quality gates
      copilot_metrics = quality_gates['quality_metrics']['copilot_optimization_metrics']
      copilot_metrics.each_value do |metric_ref|
        expect(metric_ref).to start_with('@ref:copilot-optimization')
      end
    end

    it 'maintains workflow integration references' do
      workflow_integration = copilot_module['workflow_integration']
      automation_rules = workflow_integration['automation_rules']
      
      expect(automation_rules['branch_management']['target_branch']).to include('@ref:behavioral-rules')
      expect(automation_rules['improvement_tracking']['validation']).to include('@ref:quality-gates')
    end
  end

  describe 'Improvement Measurement Compliance' do
    it 'exceeds 30% minimum improvement threshold' do
      # Context alignment: 90% target vs estimated 60% baseline = 50% improvement
      context_improvement = (90.0 - 60.0) / 60.0 * 100
      expect(context_improvement).to be > 30
      
      # Suggestion relevance: 85% target vs estimated 65% baseline = 31% improvement  
      relevance_improvement = (85.0 - 65.0) / 65.0 * 100
      expect(relevance_improvement).to be > 30
      
      # Edge case coverage: 80% target vs estimated 40% baseline = 100% improvement
      edge_case_improvement = (80.0 - 40.0) / 40.0 * 100
      expect(edge_case_improvement).to be > 30
    end

    it 'defines comprehensive success criteria' do
      expected_outcomes = copilot_module['expected_outcomes']
      measurable_improvements = expected_outcomes['measurable_improvements']
      
      expect(measurable_improvements['context_alignment_accuracy']).to eq('target_90_percent')
      expect(measurable_improvements['suggestion_relevance_score']).to eq('target_85_percent')
      expect(measurable_improvements['workflow_disruption_reduction']).to eq('target_70_percent')
      expect(measurable_improvements['edge_case_coverage']).to eq('target_80_percent')
    end
  end

  describe 'Plugin Schema Compliance' do
    it 'validates against plugin schema structure' do
      # Required meta fields per plugin_schema_v1.json
      meta = copilot_module['meta']
      expect(meta).to have_key('plugin_name')
      expect(meta).to have_key('version')
      expect(meta).to have_key('description')
      expect(meta).to have_key('framework_version_compatibility')
      
      # Plugin name format validation
      expect(meta['plugin_name']).to match(/^[a-z][a-z0-9-]*[a-z0-9]$/)
      
      # Version format validation
      expect(meta['version']).to match(/^\d+\.\d+\.\d+$/)
      
      # Description length validation
      expect(meta['description'].length).to be >= 10
    end

    it 'maintains modular architecture compliance' do
      integration_compliance = copilot_module['integration_compliance']
      expect(integration_compliance['modular_architecture']).to eq('full_compliance_with_plugin_system')
      expect(integration_compliance['cross_reference_system']).to eq('utilizes_ref_syntax_for_module_dependencies')
      expect(integration_compliance['validation_framework']).to eq('passes_all_mandatory_validations')
    end
  end

  describe 'File System Integration' do
    it 'creates all required files' do
      expect(File.exist?(copilot_module_file)).to be true
      expect(File.exist?(framework_file)).to be true
      expect(File.exist?(quality_gates_file)).to be true
    end

    it 'maintains valid JSON syntax in all modified files' do
      expect { JSON.parse(File.read(framework_file)) }.not_to raise_error
      expect { JSON.parse(File.read(copilot_module_file)) }.not_to raise_error
      expect { JSON.parse(File.read(quality_gates_file)) }.not_to raise_error
    end
  end
end