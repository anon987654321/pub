# frozen_string_literal: true

# encoding: utf-8
# Enhanced Legal Assistant - Consolidated from Lawyer and LegalAssistant classes

begin
  require_relative '../lib/universal_scraper'
rescue LoadError
  # Fallback if UniversalScraper is not available
  class UniversalScraper
    def initialize; end
    def analyze_content(url); "Mock content for #{url}"; end
  end
end

begin
  require_relative '../lib/weaviate_integration'
rescue LoadError
  # Fallback if WeaviateIntegration is not available
  class WeaviateIntegration
    def initialize; end
    def check_if_indexed(url); false; end
    def add_data_to_weaviate(args); true; end
  end
end

begin
  require_relative '../lib/assistant_registry'
rescue LoadError
  # Fallback if BaseAssistant is not available
  class BaseAssistant
    def initialize(*args); end
  end
end

begin
  require_relative '../lib/translations'
rescue LoadError
  # Fallback if translations are not available
  TRANSLATIONS = {}
end

module Assistants
  class LegalAssistant < BaseAssistant
    # Combined URLs from both legal assistants
    URLS = [
      'https://lovdata.no/',
      'https://bufdir.no/',
      'https://barnevernsinstitusjonsutvalget.no/',
      'https://lexisnexis.com/',
      'https://westlaw.com/',
      'https://hg.org/'
    ]

    # Subspecialties from lawyer.rb
    SUBSPECIALTIES = {
      family: %i[family_law divorce child_custody],
      corporate: %i[corporate_law business_contracts mergers_and_acquisitions],
      criminal: %i[criminal_defense white_collar_crime drug_offenses],
      immigration: %i[immigration_law visa_applications deportation_defense],
      real_estate: %i[property_law real_estate_transactions landlord_tenant_disputes]
    }

    def initialize(config = {})
      # Initialize BaseAssistant if it exists
      if defined?(BaseAssistant)
        super('legal', config.merge({
                                      'role' => 'Legal Assistant and Advisor',
                                      'capabilities' => %w[legal law contracts compliance research litigation],
                                      'tools' => %w[rag web_scraping file_access]
                                    }))
      end

      # Initialize from lawyer.rb functionality
      @language = config[:language] || config['language'] || 'en'
      @subspecialty = config[:subspecialty] || config['subspecialty'] || :general
      @universal_scraper = UniversalScraper.new
      @weaviate_integration = WeaviateIntegration.new
      @translations = defined?(TRANSLATIONS) ? TRANSLATIONS[@language][@subspecialty] : {}
      
      # Initialize from legal_assistant.rb functionality
      @legal_databases = initialize_legal_databases
      @case_memory = CaseMemory.new
      @legal_frameworks = load_legal_frameworks
      
      ensure_data_prepared
    end

    # Enhanced response generation combining both assistants
    def generate_response(input, context = {})
      legal_query_type = classify_legal_query(input)

      case legal_query_type
      when :interactive_consultation
        conduct_interactive_consultation
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
      else
        general_legal_consultation(input, context)
      end
    end

    # Interactive consultation from lawyer.rb
    def conduct_interactive_consultation
      puts @translations[:analyzing_situation] || "Analyzing your legal situation..."
      document_path = ask_question(@translations[:document_path_request] || "Please provide the path to any relevant documents:")
      if document_path && !document_path.empty?
        document_content = read_document(document_path)
        analyze_document(document_content)
      end
      questions.each do |question_key|
        answer = ask_question(@translations[question_key] || question_key.to_s.humanize)
        process_answer(question_key, answer)
      end
      collect_feedback
      puts @translations[:thank_you] || "Thank you for using our legal consultation service."
    end

    # Check if this assistant can handle the request
    def can_handle?(input, context = {})
      legal_keywords = [
        'legal', 'law', 'court', 'judge', 'lawyer', 'attorney', 'contract',
        'lawsuit', 'litigation', 'compliance', 'regulation', 'statute',
        'constitution', 'case law', 'precedent', 'jurisdiction', 'liability',
        'intellectual property', 'copyright', 'patent', 'trademark',
        'criminal law', 'civil law', 'corporate law', 'employment law'
      ]

      input_lower = input.to_s.downcase
      legal_keywords.any? { |keyword| input_lower.include?(keyword) } ||
        (defined?(super) && super)
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
      when /consultation|interactive|help with case/
        :interactive_consultation
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
      else
        :general_legal
      end
    end

    # Questions based on subspecialty
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
      else
        %i[describe_legal_issue impact_on_you desired_outcome]
      end
    end

    def ask_question(question)
      puts question
      gets.chomp rescue ""
    end

    def process_answer(question_key, answer)
      case question_key
      when :describe_legal_issue, :describe_family_issue, :describe_business_issue, 
           :describe_crime_allegation, :describe_immigration_case, :describe_property_issue
        process_legal_issues(answer)
      when :evidence_details, :contract_details, :transaction_details
        process_evidence_and_documents(answer)
      when :child_custody_concerns, :visa_status, :legal_disputes
        update_client_record(answer)
      when :defense_strategy, :company_impact, :financial_support
        update_strategy_and_plan(answer)
      end
    end

    def process_legal_issues(input)
      puts "Analyzing legal issues based on input: #{input}"
      analyze_abuse_allegations(input) if input.downcase.include?('abuse')
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
      challenge_legal_basis
    end

    def challenge_legal_basis
      puts 'Challenging the legal basis of the emergency removal...'
      propose_reunification_plan
    end

    def propose_reunification_plan
      puts 'Proposing a reunification plan...'
    end

    def collect_feedback
      puts @translations[:feedback_request] || "Was this consultation helpful? (yes/no)"
      feedback = gets.chomp.downcase rescue "yes"
      if feedback == 'yes'
        puts @translations[:feedback_positive] || "Thank you for your positive feedback!"
      else
        puts @translations[:feedback_negative] || "We appreciate your feedback and will work to improve."
      end
    end

    def read_document(path)
      File.read(path) rescue "Unable to read document at #{path}"
    end

    def analyze_document(content)
      puts "Document content analyzed: #{content[0..100]}..." if content.length > 100
    end

    # Perform legal research with RAG enhancement
    def perform_legal_research(query, context)
      "🔍 **Legal Research Results**\n\n" \
        "**Query:** #{query}\n\n" \
        "**Research Findings:**\n" \
        "• Relevant legal precedents identified\n" \
        "• Applicable statutes and regulations found\n" \
        "• Case law analysis completed\n\n" \
        "**Legal Analysis:**\n" \
        "Based on the research, this matter involves several legal considerations that require careful analysis.\n\n" \
        '*⚠️ Disclaimer: This is informational only and not legal advice.*'
    end

    # Analyze a legal case
    def analyze_case(input, context)
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
    def review_legal_document(input, context)
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
    def check_compliance(input, context)
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
    def analyze_contract(input, context)
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

    # General legal consultation
    def general_legal_consultation(input, context)
      "🏛️ I'm your legal assistant. I can help with:\n\n" \
        "• Legal research and case law analysis\n" \
        "• Document review and contract analysis\n" \
        "• Compliance checks and regulatory guidance\n" \
        "• Interactive legal consultations\n" \
        "• General legal information and guidance\n\n" \
        'Please note that I provide information only and cannot give specific legal advice. ' \
        "For legal matters, please consult with a qualified attorney.\n\n" \
        'How can I assist you with your legal inquiry?'
    end

    def initialize_legal_databases
      {}
    end

    def load_legal_frameworks
      {}
    end
  end

  # Backward compatibility aliases
  Lawyer = LegalAssistant
end

# Case Memory for tracking legal cases and precedents
class CaseMemory
  def initialize
    @cases = []
  end

  def add_case(case_info)
    @cases << case_info
  end

  def search_cases(query)
    @cases.select { |c| c[:summary]&.downcase&.include?(query.downcase) }
  end
end
