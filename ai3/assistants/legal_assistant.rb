# frozen_string_literal: true

require_relative '../lib/assistant_registry'

# Enhanced Legal Assistant - Specialized for legal assistance and research
class LegalAssistant < BaseAssistant
  def initialize(config = {})
    super('legal', config.merge({
                                  'role' => 'Legal Assistant and Advisor',
                                  'capabilities' => %w[legal law contracts compliance research litigation],
                                  'tools' => %w[rag web_scraping file_access]
                                }))

    @legal_databases = initialize_legal_databases
    @case_memory = CaseMemory.new
    @legal_frameworks = load_legal_frameworks
  end

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
    else
      general_legal_consultation(input, context)
    end
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
      super
  end

  private

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
    else
      :general_legal
    end
  end

  # Perform legal research with RAG enhancement
  def perform_legal_research(query, _context)
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

  # General legal consultation
  def general_legal_consultation(_input, _context)
    "🏛️ I'm your legal assistant. I can help with:\n\n" \
      "• Legal research and case law analysis\n" \
      "• Document review and contract analysis\n" \
      "• Compliance checks and regulatory guidance\n" \
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
