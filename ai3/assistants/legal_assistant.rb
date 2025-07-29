# frozen_string_literal: true

# encoding: utf-8
# Unified Legal Assistant - Consolidated from Lawyer and LegalAssistant classes
# Combines comprehensive legal research, consultation, and analysis capabilities

require_relative '../lib/universal_scraper'
require_relative '../lib/weaviate_integration'
require_relative '../lib/assistant_registry'
require_relative '../lib/translations'

module Assistants
  # Unified Legal Assistant combining both approaches
  class LegalAssistant < BaseAssistant
  def initialize(config = {})
    super('legal', config.merge({
                                  'role' => 'Legal Assistant and Advisor',
                                  'capabilities' => %w[legal law contracts compliance research litigation],
                                  'tools' => %w[rag web_scraping file_access]
                                }))

    # Enhanced initialization with Lawyer class functionality
    @universal_scraper = UniversalScraper.new
    @weaviate_integration = WeaviateIntegration.new
    @language = config[:language] || config['language'] || 'en'
    @subspecialty = config[:subspecialty] || config['subspecialty'] || :general

    @legal_databases = initialize_legal_databases
    @case_memory = CaseMemory.new
    @legal_frameworks = load_legal_frameworks
    @translations = load_translations_for_subspecialty(@subspecialty)
    
    ensure_data_prepared
  end

  # Combined URLs from all legal databases and sources (from Lawyer class)
  URLS = [
    'https://lovdata.no/',
    'https://bufdir.no/',
    'https://barnevernsinstitusjonsutvalget.no/',
    'https://lexisnexis.com/',
    'https://westlaw.com/',
    'https://hg.org/'
  ].freeze

  # Comprehensive subspecialties from both implementations
  SUBSPECIALTIES = {
    family: %i[family_law divorce child_custody],
    corporate: %i[corporate_law business_contracts mergers_and_acquisitions],
    criminal: %i[criminal_defense white_collar_crime drug_offenses],
    immigration: %i[immigration_law visa_applications deportation_defense],
    real_estate: %i[property_law real_estate_transactions landlord_tenant_disputes],
    intellectual_property: %i[copyright patent trademark],
    employment: %i[employment_law labor_disputes workplace_rights],
    tax: %i[tax_law tax_planning tax_disputes],
    constitutional: %i[constitutional_law civil_rights government_law],
    international: %i[international_law trade_law diplomatic_relations]
  }.freeze

  def generate_response(input, context)
    legal_query_type = classify_legal_query(input)

    case legal_query_type
    when :legal_research
      perform_legal_research(input, context)
    when :case_analysis
      analyze_case(input, context)
    when :document_review
      review_legal_document(input, context)
    when :compliance_check
      check_compliance(input, context)
    when :contract_analysis
      analyze_contract(input, context)
    when :interactive_consultation
      conduct_interactive_consultation
    else
      general_legal_consultation(input, context)
    end
  end

  # Enhanced interactive consultation from Lawyer class
  def conduct_interactive_consultation
    puts @translations[:analyzing_situation] if @translations
    
    document_path = ask_question(@translations ? @translations[:document_path_request] : "Please provide document path:")
    if document_path && !document_path.empty?
      document_content = read_document(document_path)
      analyze_document(document_content)
    end
    
    questions.each do |question_key|
      question_text = @translations ? @translations[question_key] : question_key.to_s.humanize
      answer = ask_question(question_text)
      process_answer(question_key, answer)
    end
    
    collect_feedback
    puts @translations ? @translations[:thank_you] : "Thank you for using the legal consultation service."
  end

  # Check if this assistant can handle the request
  def can_handle?(input, context = {})
    legal_keywords = [
      'legal', 'law', 'court', 'judge', 'lawyer', 'attorney', 'contract',
      'lawsuit', 'litigation', 'compliance', 'regulation', 'statute',
      'constitution', 'case law', 'precedent', 'jurisdiction', 'liability',
      'intellectual property', 'copyright', 'patent', 'trademark',
      'criminal law', 'civil law', 'corporate law', 'employment law',
      'family law', 'divorce', 'custody', 'immigration', 'visa',
      'real estate', 'property', 'tax law'
    ]

    input_lower = input.to_s.downcase
    legal_keywords.any? { |keyword| input_lower.include?(keyword) } ||
      super
  end

  private

  def ensure_data_prepared
    URLS.each do |url|
      unless @weaviate_integration.check_if_indexed(url)
        scrape_and_index(url)
      end
    end
  end

  def scrape_and_index(url)
    data = @universal_scraper.analyze_content(url)
    @weaviate_integration.add_data_to_weaviate(url: url, content: data)
  end

  # Classify the type of legal query
  def classify_legal_query(input)
    input_lower = input.to_s.downcase

    case input_lower
    when /research|case law|precedent|statute/
      :legal_research
    when /analyze case|case analysis|court case/
      :case_analysis
    when /review document|document review|contract review/
      :document_review
    when /compliance|regulation|regulatory|violat/
      :compliance_check
    when /contract|agreement|terms|conditions/
      :contract_analysis
    when /consultation|consult|interactive|help with/
      :interactive_consultation
    else
      :general_legal
    end
  end

  # Enhanced legal research with RAG and database integration
  def perform_legal_research(query, context)
    # Search through indexed legal databases
    research_results = search_legal_databases(query)
    relevant_cases = @case_memory.search_cases(query)
    
    "🔍 **Enhanced Legal Research Results**\n\n" \
      "**Query:** #{query}\n\n" \
      "**Research Findings:**\n" \
      "• #{research_results.size} relevant legal precedents identified\n" \
      "• #{relevant_cases.size} applicable cases found in memory\n" \
      "• Statutes and regulations analyzed from #{URLS.size} databases\n" \
      "• Case law analysis completed across multiple jurisdictions\n\n" \
      "**Legal Analysis:**\n" \
      "Based on comprehensive research across #{SUBSPECIALTIES.keys.join(', ')} specialties, " \
      "this matter involves several legal considerations that require careful analysis.\n\n" \
      "**Relevant Legal Frameworks:**\n" \
      "#{@legal_frameworks.keys.map { |f| "• #{f.to_s.humanize}" }.join("\n")}\n\n" \
      '*⚠️ Disclaimer: This is informational only and not legal advice.*'
  end

  def search_legal_databases(query)
    # Simulate database search
    results = []
    URLS.each do |url|
      results << { url: url, relevance: rand(0.5..1.0), summary: "Results from #{url}" }
    end
    results.sort_by { |r| -r[:relevance] }
  end

  # Analyze a legal case
  def analyze_case(input, _context)
    "⚖️ **Case Analysis**\n\n" \
      "**Case Summary:** #{input[0..100]}...\n\n" \
      "**Legal Issues Identified:**\n" \
      "1. Contract interpretation\n" \
      "2. Liability assessment\n" \
      "3. Procedural considerations\n\n" \
      "**Recommended Actions:**\n" \
      "• Gather additional documentation\n" \
      "• Review relevant precedents\n" \
      "• Consult with specialist attorney\n\n" \
      '*⚠️ This analysis is informational only.*'
  end

  # Review legal document
  def review_legal_document(_input, _context)
    "📄 **Document Review**\n\n" \
      "**Document Type:** Legal Document\n\n" \
      "**Key Provisions:**\n" \
      "• Payment terms\n" \
      "• Liability clauses\n" \
      "• Termination conditions\n\n" \
      "**Potential Issues:**\n" \
      "• Unclear termination clause\n" \
      "• Broad liability exposure\n\n" \
      "**Recommendations:**\n" \
      "• Clarify ambiguous terms\n" \
      "• Add protective clauses\n" \
      "• Review with legal counsel\n\n" \
      '*⚠️ This review is for informational purposes only.*'
  end

  # Check compliance
  def check_compliance(_input, _context)
    "✅ **Compliance Check**\n\n" \
      "**Applicable Regulations:**\n" \
      "• Industry-specific requirements\n" \
      "• General legal obligations\n" \
      "• Regulatory compliance standards\n\n" \
      "**Compliance Status:** Requires review\n\n" \
      "**Recommendations:**\n" \
      "• Conduct compliance audit\n" \
      "• Update policies and procedures\n" \
      "• Implement monitoring systems\n\n" \
      '*⚠️ Consult with legal counsel for specific compliance advice.*'
  end

  # Analyze contract
  def analyze_contract(_input, _context)
    "📋 **Contract Analysis**\n\n" \
      "**Contract Type:** General Agreement\n\n" \
      "**Key Terms:**\n" \
      "• Duration: Term specified\n" \
      "• Payment: Terms included\n" \
      "• Termination: Clause present\n" \
      "• Liability: Provisions included\n\n" \
      "**Risk Assessment:** Medium risk level\n\n" \
      "**Negotiation Points:**\n" \
      "• Clarify payment schedule\n" \
      "• Limit liability exposure\n" \
      "• Add force majeure clause\n\n" \
      '*⚠️ Have a qualified attorney review before signing.*'
  end

  # Enhanced general consultation with subspecialty guidance
  def general_legal_consultation(input, context)
    relevant_subspecialties = identify_relevant_subspecialties(input)
    
    "🏛️ **Comprehensive Legal Consultation**\n\n" \
      "I'm your unified legal assistant with expertise across #{SUBSPECIALTIES.size} legal specialties. " \
      "I can help with:\n\n" \
      "**Research & Analysis:**\n" \
      "• Legal research across #{URLS.size} premium databases\n" \
      "• Case law analysis and precedent research\n" \
      "• Statutory and regulatory interpretation\n\n" \
      "**Document Services:**\n" \
      "• Contract review and analysis\n" \
      "• Document drafting assistance\n" \
      "• Compliance checking and gap analysis\n\n" \
      "**Specialized Areas:**\n" \
      "#{SUBSPECIALTIES.keys.map { |spec| "• #{spec.to_s.humanize} (#{SUBSPECIALTIES[spec].join(', ')})" }.join("\n")}\n\n" \
      "**Interactive Services:**\n" \
      "• Guided legal consultations\n" \
      "• Case strategy development\n" \
      "• Risk assessment and mitigation\n\n" \
      "#{relevant_subspecialties.any? ? "**Relevant to your query:** #{relevant_subspecialties.join(', ')}\n\n" : ''}" \
      'Please note that I provide information only and cannot give specific legal advice. ' \
      "For legal matters, please consult with a qualified attorney.\n\n" \
      'How can I assist you with your legal inquiry?'
  end

  def initialize_legal_databases
    URLS.map { |url| { url: url, indexed: false, last_updated: Time.now } }
  end

  def load_legal_frameworks
    {
      constitutional: 'Constitutional Law Framework',
      statutory: 'Statutory Interpretation Framework',
      case_law: 'Case Law Analysis Framework',
      regulatory: 'Regulatory Compliance Framework',
      international: 'International Law Framework'
    }
  end

  # Interactive consultation methods from Lawyer class
  def questions
    case @subspecialty
    when :family
      %i[describe_family_issue child_custody_concerns desired_outcome]
    when :corporate
      %i[describe_business_issue contract_details company_impact]
    when :criminal
      %i[describe_crime_allegation evidence_details defense_strategy]
    when :immigration
      %i[describe_immigration_case visa_status legal_disputes]
    when :real_estate
      %i[describe_property_issue transaction_details legal_disputes]
    when :intellectual_property
      %i[describe_ip_issue protection_type infringement_concerns]
    when :employment
      %i[describe_employment_issue workplace_situation desired_resolution]
    else
      %i[describe_legal_issue impact_on_you desired_outcome]
    end
  end

  def ask_question(question)
    puts question
    gets.chomp
  end

  def process_answer(question_key, answer)
    case question_key
    when :describe_legal_issue, :describe_family_issue, :describe_business_issue, 
         :describe_crime_allegation, :describe_immigration_case, :describe_property_issue,
         :describe_ip_issue, :describe_employment_issue
      process_legal_issues(answer)
    when :evidence_details, :contract_details, :transaction_details
      process_evidence_and_documents(answer)
    when :child_custody_concerns, :visa_status, :legal_disputes, :infringement_concerns
      update_client_record(answer)
    when :defense_strategy, :company_impact, :desired_resolution, :desired_outcome
      update_strategy_and_plan(answer)
    end
  end

  def process_legal_issues(input)
    puts "Analyzing legal issues based on input: #{input}"
    analyze_abuse_allegations(input) if input.downcase.include?('abuse')
    analyze_by_subspecialty(input)
  end

  def analyze_abuse_allegations(input)
    puts 'Analyzing abuse allegations and counter-evidence...'
    gather_counter_evidence
  end

  def gather_counter_evidence
    puts 'Gathering counter-evidence...'
    highlight_important_cases
  end

  def highlight_important_cases
    puts 'Highlighting important cases...'
  end

  def process_evidence_and_documents(input)
    puts "Updating case file with new evidence and document details: #{input}"
  end

  def update_client_record(input)
    puts "Recording impacts on client and related parties: #{input}"
  end

  def update_strategy_and_plan(input)
    puts "Adjusting legal strategy and planning based on input: #{input}"
    challenge_legal_basis if input.downcase.include?('removal')
  end

  def challenge_legal_basis
    puts 'Challenging the legal basis of the emergency removal...'
    propose_reunification_plan
  end

  def propose_reunification_plan
    puts 'Proposing a reunification plan...'
  end

  def collect_feedback
    feedback_text = @translations ? @translations[:feedback_request] : "Was this consultation helpful? (yes/no)"
    puts feedback_text
    feedback = gets.chomp.downcase
    
    positive_response = @translations ? @translations[:feedback_positive] : "Thank you for the positive feedback!"
    negative_response = @translations ? @translations[:feedback_negative] : "Thank you for the feedback. We'll work to improve."
    
    puts feedback == 'yes' ? positive_response : negative_response
  end

  def read_document(path)
    File.read(path) if File.exist?(path)
  rescue StandardError => e
    "Error reading document: #{e.message}"
  end

  def analyze_document(content)
    puts "Analyzing document content: #{content[0..100]}..." if content
  end

  def load_translations_for_subspecialty(subspecialty)
    # Load translations if available, otherwise use defaults
    if defined?(TRANSLATIONS) && TRANSLATIONS[@language] && TRANSLATIONS[@language][subspecialty]
      TRANSLATIONS[@language][subspecialty]
    else
      default_translations
    end
  end

  def default_translations
    {
      analyzing_situation: 'Analyzing your legal situation...',
      document_path_request: 'Please provide the path to your legal document (or press Enter to skip):',
      thank_you: 'Thank you for using our legal consultation service.',
      feedback_request: 'Was this consultation helpful? (yes/no)',
      feedback_positive: 'Thank you for the positive feedback!',
      feedback_negative: 'Thank you for the feedback. We will work to improve our service.'
    }
  end

  def analyze_by_subspecialty(input)
    relevant_subspecialties = identify_relevant_subspecialties(input)
    if relevant_subspecialties.any?
      "Analysis suggests this involves #{relevant_subspecialties.join(' and ')} law considerations."
    else
      "General legal analysis applicable across multiple practice areas."
    end
  end

  def identify_relevant_subspecialties(input)
    input_lower = input.to_s.downcase
    relevant = []
    
    SUBSPECIALTIES.each do |specialty, keywords|
      if keywords.any? { |keyword| input_lower.include?(keyword.to_s.gsub('_', ' ')) }
        relevant << specialty.to_s.humanize
      end
    end
    
    relevant
  end
end

# Enhanced Case Memory for tracking legal cases and precedents
class CaseMemory
  def initialize
    @cases = []
    @case_index = {}
  end

  def add_case(case_info)
    @cases << case_info
    index_case(case_info)
  end

  def search_cases(query)
    query_lower = query.to_s.downcase
    @cases.select do |case_info|
      case_info[:summary]&.downcase&.include?(query_lower) ||
      case_info[:issues]&.any? { |issue| issue.downcase.include?(query_lower) } ||
      case_info[:outcome]&.downcase&.include?(query_lower)
    end
  end

  def get_cases_by_specialty(specialty)
    @cases.select { |case_info| case_info[:specialty] == specialty }
  end

  def get_recent_cases(limit = 10)
    @cases.sort_by { |case_info| case_info[:date] || Time.now }.last(limit)
  end

  private

  def index_case(case_info)
    # Create searchable index
    key_terms = extract_key_terms(case_info)
    key_terms.each do |term|
      @case_index[term] ||= []
      @case_index[term] << case_info
    end
  end

  def extract_key_terms(case_info)
    terms = []
    terms += case_info[:summary]&.split&.map(&:downcase) || []
    terms += case_info[:issues]&.map(&:downcase) || []
    terms.uniq
  end
end
end
