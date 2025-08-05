# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../../lib/weaviate_integration'

class WeaviateIntegrationTest < Minitest::Test
  def setup
    @weaviate = WeaviateIntegration.new
  end

  def test_initialization
    assert_respond_to @weaviate, :client
    assert_respond_to @weaviate, :config
    assert_respond_to @weaviate, :legal_schema
  end

  def test_legal_schema_classes_defined
    schema = @weaviate.legal_schema
    
    assert schema[:document_schema]
    assert schema[:law_reference_schema]
    assert schema[:court_decision_schema]
    
    assert_equal 'NorwegianLegalDocument', schema[:document_schema][:class]
    assert_equal 'NorwegianLawReference', schema[:law_reference_schema][:class]
    assert_equal 'NorwegianCourtDecision', schema[:court_decision_schema][:class]
  end

  def test_document_id_generation
    url1 = 'https://lovdata.no/dokument/NL/lov/1918-05-31-4'
    url2 = 'https://lovdata.no/dokument/NL/lov/2005-06-17-62'
    
    id1 = @weaviate.send(:generate_document_id, url1)
    id2 = @weaviate.send(:generate_document_id, url2)
    
    assert_kind_of String, id1
    assert_kind_of String, id2
    refute_equal id1, id2
    
    # Should be deterministic
    assert_equal id1, @weaviate.send(:generate_document_id, url1)
  end

  def test_content_structuring
    url = 'https://lovdata.no/dokument/NL/lov/1918-05-31-4'
    content = {
      title: 'Avtaleloven',
      content: 'avtale kontrakt ansvar erstatning LOV 1918-05-31 nr 4',
      html: '<html><body>Legal content</body></html>'
    }
    
    structured = @weaviate.send(:structure_legal_content, url, content)
    
    assert_equal 'Avtaleloven', structured[:title]
    assert_equal 'norwegian_law', structured[:document_type]
    assert_equal 'norwegian', structured[:language]
    assert_includes structured[:legal_keywords], 'avtale'
    assert structured[:law_references].any?
  end

  def test_document_type_detection
    url_law = 'https://lovdata.no/dokument/NL/lov/1918-05-31-4'
    url_regulation = 'https://lovdata.no/dokument/SF/forskrift/2011-12-06-1357'
    url_court = 'https://domstol.no/hr-2023-1234-a'
    url_pdf = 'file:///docs/contract.pdf'
    
    assert_equal 'norwegian_law', @weaviate.send(:determine_document_type_from_url, url_law)
    assert_equal 'norwegian_regulation', @weaviate.send(:determine_document_type_from_url, url_regulation)
    assert_equal 'court_decision', @weaviate.send(:determine_document_type_from_url, url_court)
    assert_equal 'legal_document_pdf', @weaviate.send(:determine_document_type_from_url, url_pdf)
  end

  def test_law_area_detection
    contract_content = 'kontrakt avtale kjøp salg forbruker'
    employment_content = 'arbeid ansatt lønn ferie overtid'
    criminal_content = 'straff kriminal lovbrudd'
    
    assert_equal 'contract_law', @weaviate.send(:determine_law_area_from_content, contract_content)
    assert_equal 'employment_law', @weaviate.send(:determine_law_area_from_content, employment_content)
    assert_equal 'criminal_law', @weaviate.send(:determine_law_area_from_content, criminal_content)
  end

  def test_language_detection
    norwegian_content = 'Dette er en norsk tekst med mange norske ord og for og med til av på'
    english_content = 'This is an English text with many English words and for and with to of on'
    
    assert_equal 'norwegian', @weaviate.send(:detect_language, norwegian_content)
    assert_equal 'english', @weaviate.send(:detect_language, english_content)
  end

  def test_legal_keywords_extraction
    content = 'Dette er en lov om kontrakt og ansvar med forskrift og retningslinje'
    keywords = @weaviate.send(:extract_legal_keywords, content)
    
    assert_includes keywords, 'lov'
    assert_includes keywords, 'kontrakt'
    assert_includes keywords, 'ansvar'
    assert_includes keywords, 'forskrift'
    assert_includes keywords, 'retningslinje'
  end

  def test_law_references_extraction
    content = 'Se LOV 2005-06-17-62 og FOR 2011-12-06-1357 for detaljer'
    references = @weaviate.send(:extract_law_references_structured, content)
    
    assert references.any? { |ref| ref[:law_type] == 'LOV' }
    assert references.any? { |ref| ref[:law_type] == 'FOR' }
    assert references.any? { |ref| ref[:date_enacted] == '2005-06-17' }
  end

  def test_court_decisions_extraction
    content = 'Se Rt. 2023 s. 456 og HR-2023-1234-A for relevante avgjørelser'
    decisions = @weaviate.send(:extract_court_decisions_structured, content)
    
    assert decisions.any? { |dec| dec[:citation] == 'Rt. 2023 s. 456' }
    assert decisions.any? { |dec| dec[:case_number] == 'HR-2023-1234-A' }
  end

  def test_lovdata_reference_extraction
    lovdata_url = 'https://lovdata.no/dokument/NL/lov/1918-05-31-4'
    content_with_ref = 'LOV 2005-06-17-62 gjelder for dette området'
    content_without_ref = 'Generell juridisk tekst uten referanser'
    
    assert_equal lovdata_url, @weaviate.send(:extract_lovdata_reference, lovdata_url, '')
    assert_equal 'LOV 2005-06-17-62', @weaviate.send(:extract_lovdata_reference, '', content_with_ref)
    assert_nil @weaviate.send(:extract_lovdata_reference, '', content_without_ref)
  end

  def test_indexing_without_weaviate_server
    # Test that it gracefully handles missing Weaviate server
    url = 'https://lovdata.no/test'
    content = { title: 'Test', content: 'Test content' }
    
    result = @weaviate.add_data_to_weaviate(url: url, content: content)
    
    # Should return a warning message since no real Weaviate server is running
    assert_includes result.to_s, 'Client not available'
  end

  def test_search_without_weaviate_server
    # Test that search returns mock results when server is not available
    results = @weaviate.search_legal_documents('contract law')
    
    assert results[:total_results]
    assert results[:documents]
    assert results[:documents].first[:title]
  end

  def test_norwegian_law_search
    results = @weaviate.search_norwegian_laws('kontrakt')
    
    assert results[:total_results]
    assert results[:documents]
  end

  def test_court_precedent_search
    results = @weaviate.search_court_precedents('ansvar')
    
    assert results[:total_results]
    assert results[:documents]
  end

  def test_mock_search_results_structure
    results = @weaviate.send(:mock_search_results, 'test query')
    
    assert_equal 3, results[:total_results]
    assert_equal 3, results[:documents].size
    
    first_doc = results[:documents].first
    assert first_doc[:title]
    assert first_doc[:content_preview]
    assert first_doc[:document_type]
    assert first_doc[:law_area]
    assert first_doc[:source_url]
    assert first_doc[:score]
    assert first_doc[:legal_keywords]
  end

  def test_where_filter_building
    filters = { document_type: 'norwegian_law', language: 'norwegian' }
    where_filter = @weaviate.send(:build_where_filter, filters)
    
    assert where_filter[:operator] == 'And'
    assert where_filter[:operands].size == 2
  end

  def test_legal_search_query_building
    query = 'contract law'
    filters = { document_type: 'law' }
    search_query = @weaviate.send(:build_legal_search_query, query, filters)
    
    assert search_query[:query]
    assert search_query[:query][:Get]
    assert search_query[:query][:Get]['NorwegianLegalDocument']
  end
end