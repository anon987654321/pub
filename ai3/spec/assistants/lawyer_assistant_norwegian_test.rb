# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../../assistants/lawyer_assistant'

class LawyerAssistantNorwegianTest < Minitest::Test
  def setup
    @target = { name: 'Test Client' }
    @case_data = {
      case_type: 'contract',
      key_facts: ['Norwegian contract dispute', 'Potential mislighold'],
      communication_history: [
        { id: 1, text: 'I am worried about this contract issue' },
        { id: 2, text: 'The other party seems angry' }
      ]
    }
    @lawyer_assistant = LawyerAssistant.new(@target, @case_data)
  end

  def test_initialization_with_norwegian_law_components
    assert_respond_to @lawyer_assistant, :norwegian_law_db
    assert_respond_to @lawyer_assistant, :process_legal_documents_from_docs
    assert_respond_to @lawyer_assistant, :research_norwegian_law
    assert_respond_to @lawyer_assistant, :generate_norwegian_citation
  end

  def test_norwegian_law_areas_defined
    assert LawyerAssistant::NORWEGIAN_LAW_AREAS.include?(:family_law)
    assert LawyerAssistant::NORWEGIAN_LAW_AREAS.include?(:contract_law)
    assert LawyerAssistant::NORWEGIAN_LAW_AREAS.include?(:criminal_law)
    assert_equal 'Familierett', LawyerAssistant::NORWEGIAN_LAW_AREAS[:family_law]
  end

  def test_norwegian_courts_defined
    assert LawyerAssistant::NORWEGIAN_COURTS.include?(:supreme_court)
    assert_equal 'Høyesterett', LawyerAssistant::NORWEGIAN_COURTS[:supreme_court]
    assert_includes LawyerAssistant::NORWEGIAN_COURTS[:appeal_courts], 'Borgarting'
  end

  def test_document_type_determination
    contract_content = 'kontrakt avtale between parties'
    assert_equal :contract, @lawyer_assistant.determine_document_type(contract_content)
    
    litigation_content = 'søksmål rettssak court case'
    assert_equal :litigation, @lawyer_assistant.determine_document_type(litigation_content)
    
    employment_content = 'arbeidskontrakt employment contract'
    assert_equal :employment, @lawyer_assistant.determine_document_type(employment_content)
  end

  def test_norwegian_law_reference_extraction
    content = <<~TEXT
      Dette er en kontrakt som refererer til:
      - LOV 2005-06-17-62 (Arbeidsmiljøloven)
      - FOR 2011-12-06-1357 (Forskrift om arbeidstid)
      - Straffeloven § 255
    TEXT
    
    references = @lawyer_assistant.extract_norwegian_law_references(content)
    references_text = references.join(' ')
    assert_includes references_text, 'LOV 2005-06-17-62', "Expected to find LOV reference, got: #{references_text}"
    assert_includes references_text, 'FOR 2011-12-06-1357', "Expected to find FOR reference, got: #{references_text}"
  end

  def test_legal_terms_extraction
    content = 'kontrakt med ansvar for erstatning ved mislighold av avtale'
    terms = @lawyer_assistant.extract_legal_terms(content)
    
    assert_includes terms, 'kontrakt'
    assert_includes terms, 'ansvar'
    assert_includes terms, 'erstatning'
    assert_includes terms, 'mislighold'
    assert_includes terms, 'avtale'
  end

  def test_legal_risk_assessment
    content = 'ubegrenset ansvar for skade uten noen beskyttelse'
    risks = @lawyer_assistant.assess_legal_risks(content)
    
    assert_includes risks, 'Liability exposure'
    assert_includes risks, 'Missing force majeure'
  end

  def test_norwegian_compliance_checking
    content = 'personopplysninger behandles med samtykke i henhold til GDPR'
    compliance = @lawyer_assistant.check_norwegian_compliance(content)
    
    assert compliance['Personal Data Protection']
    assert_equal true, @lawyer_assistant.check_gdpr_compliance(content)
  end

  def test_legal_citation_analysis
    content = 'Se Rt. 2023 s. 456 og RG. 2022 s. 123 for relevant praksis'
    citations = @lawyer_assistant.analyze_legal_citations(content)
    
    assert_includes citations, 'Rt. 2023 s. 456'
    assert_includes citations, 'RG. 2022 s. 123'
  end

  def test_relevant_norwegian_laws_finding
    query = 'contract dispute'
    laws = @lawyer_assistant.find_relevant_norwegian_laws(query)
    
    assert_includes laws, 'Avtaleloven'
    assert_includes laws, 'Kjøpsloven'
  end

  def test_norwegian_legal_recommendations_generation
    query = 'employment contract dispute'
    recommendations = @lawyer_assistant.generate_norwegian_legal_recommendations(query)
    
    assert_includes recommendations.join(' '), 'Arbeidsmiljøloven'
    assert recommendations.any? { |rec| rec.include?('employment protection') }
  end

  def test_norwegian_citation_formatting
    statute_ref = {
      type: :statute,
      law_name: 'Avtaleloven',
      date: '1918-05-31',
      number: '4'
    }
    
    citation = @lawyer_assistant.generate_norwegian_citation(statute_ref)
    assert_equal 'Avtaleloven 1918-05-31 nr. 4', citation
    
    court_ref = {
      type: :court_decision,
      court: 'Høyesterett',
      year: '2023',
      page: '456'
    }
    
    citation = @lawyer_assistant.generate_norwegian_citation(court_ref)
    assert_equal 'Rt. 2023 s. 456', citation
  end

  def test_norwegian_legal_database_initialization
    db = @lawyer_assistant.norwegian_law_db
    
    assert db[:statutes].include?('avtaleloven')
    assert db[:legal_terms].include?('erstatning')
    assert_equal 'damages/compensation', db[:legal_terms]['erstatning']
  end

  def test_docs_directory_scanning
    # This test assumes the sample documents exist
    documents = @lawyer_assistant.scan_docs_directory
    
    # Should find our sample documents
    assert documents.any? { |doc| doc.include?('sample_norwegian_contract.txt') }
    assert documents.any? { |doc| doc.include?('sample_court_decision.txt') }
  end

  def test_process_legal_document_analysis
    # Test with sample contract
    sample_contract_path = '/home/runner/work/pub/pub/docs/sample_norwegian_contract.txt'
    
    # Skip if file doesn't exist (for environments without the sample file)
    skip unless File.exist?(sample_contract_path)
    
    result = @lawyer_assistant.process_legal_document(sample_contract_path)
    
    assert_equal :employment, result[:type]
    assert result[:norwegian_law_references].any?
    assert result[:key_terms].include?('ansvar')
    assert result[:compliance_check]['Employment Law']
  end

  def test_full_report_generation
    report = @lawyer_assistant.generate_full_report
    
    assert_includes report, 'Comprehensive Norwegian Legal Report'
    assert_includes report, 'Norwegian Legal Analysis'
    assert_includes report, 'Document Analysis'
    assert_includes report, 'Legal Research Results'
    assert_includes report, 'Strategic Recommendations'
    assert_includes report, 'Compliance Assessment'
    assert_includes report, 'qualified Norwegian attorney'
  end

  def test_law_area_determination
    # Test with different case types
    @case_data[:case_type] = 'family dispute'
    family_area = @lawyer_assistant.determine_law_area
    assert_includes family_area, 'Family'
    assert_includes family_area, 'Familierett'
    
    @case_data[:case_type] = 'criminal case'
    criminal_area = @lawyer_assistant.determine_law_area
    assert_includes criminal_area, 'Criminal'
    assert_includes criminal_area, 'Strafferet'
  end

  def test_lovdata_indexing_attempt
    # Test that Lovdata indexing is attempted (should not raise errors)
    begin
      @lawyer_assistant.ensure_lovdata_indexed
      assert true, "Lovdata indexing completed without errors"
    rescue StandardError => e
      flunk "Lovdata indexing failed: #{e.message}"
    end
  end

  def test_norwegian_legal_research
    research_result = @lawyer_assistant.research_norwegian_law('contract breach')
    
    assert research_result[:query]
    assert research_result[:relevant_laws]
    assert research_result[:court_precedents]
    assert research_result[:recommendations]
  end
end