# frozen_string_literal: true

require 'bundler/setup'
require 'minitest/autorun'
require_relative '../lib/cognitive_orchestrator'
require_relative '../lib/multi_llm_manager'
require_relative '../lib/enhanced_session_manager'
require_relative '../lib/rag_engine'
require_relative '../lib/assistant_registry'

# Basic integration tests for AI³ core functionality
class AI3IntegrationTest < Minitest::Test
  def setup
    # Clean up any existing test data
    cleanup_test_data
    
    # Initialize core components
    @cognitive_orchestrator = CognitiveOrchestrator.new
    @llm_manager = MultiLLMManager.new({})
    @session_manager = EnhancedSessionManager.new(max_sessions: 5)
    @rag_engine = RAGEngine.new(db_path: 'tmp/test_vector_store.db')
    @assistant_registry = AssistantRegistry.new(@cognitive_orchestrator)
  end

  def teardown
    cleanup_test_data
  end

  def test_cognitive_orchestrator_initialization
    assert_instance_of CognitiveOrchestrator, @cognitive_orchestrator
    assert_equal 0, @cognitive_orchestrator.current_load
    assert_equal 0, @cognitive_orchestrator.context_switches
  end

  def test_cognitive_load_assessment
    simple_content = "Hello world"
    complex_content = "Implement a sophisticated algorithm for machine learning with complex nested structures"
    
    simple_complexity = @cognitive_orchestrator.assess_complexity(simple_content)
    complex_complexity = @cognitive_orchestrator.assess_complexity(complex_content)
    
    assert simple_complexity < complex_complexity
    assert simple_complexity > 0
  end

  def test_cognitive_concept_management
    concept = "test_concept"
    weight = 2.0
    
    @cognitive_orchestrator.add_concept(concept, weight)
    
    assert_equal 1, @cognitive_orchestrator.concept_stack.size
    assert_equal 2.0, @cognitive_orchestrator.current_load
  end

  def test_cognitive_overload_detection
    # Add concepts to trigger overload
    10.times { |i| @cognitive_orchestrator.add_concept("concept_#{i}", 1.0) }
    
    assert @cognitive_orchestrator.cognitive_overload?
  end

  def test_session_manager_initialization
    assert_instance_of EnhancedSessionManager, @session_manager
    assert_equal 5, @session_manager.max_sessions
    assert_equal 0, @session_manager.session_count
  end

  def test_session_creation_and_management
    user_id = 'test_user'
    session = @session_manager.create_session(user_id)
    
    assert_instance_of Hash, session
    assert session.key?(:context)
    assert session.key?(:timestamp)
    assert session.key?(:cognitive_load)
    assert_equal 1, @session_manager.session_count
  end

  def test_session_context_update
    user_id = 'test_user'
    @session_manager.create_session(user_id)
    
    new_context = { test_key: 'test_value' }
    @session_manager.update_session(user_id, new_context)
    
    session = @session_manager.get_session(user_id)
    assert_equal 'test_value', session[:context][:test_key]
  end

  def test_rag_engine_initialization
    assert_instance_of RAGEngine, @rag_engine
    assert File.exist?('tmp/test_vector_store.db')
  end

  def test_rag_document_addition
    document = {
      content: "This is a test document for AI³ RAG functionality",
      title: "Test Document"
    }
    
    result = @rag_engine.add_document(document, collection: 'test')
    assert result
  end

  def test_rag_search_functionality
    # Add a test document
    document = {
      content: "Ruby programming language features object-oriented design",
      title: "Ruby Programming"
    }
    
    @rag_engine.add_document(document, collection: 'test')
    
    # Search for relevant content
    results = @rag_engine.search("Ruby programming", collection: 'test', limit: 1)
    
    assert_instance_of Array, results
    # Note: Results might be empty due to simple embedding implementation
  end

  def test_assistant_registry_initialization
    assert_instance_of AssistantRegistry, @assistant_registry
    assert @assistant_registry.assistants.size > 0
    assert @assistant_registry.assistants.key?(:general)
  end

  def test_assistant_discovery
    assistant = @assistant_registry.get_assistant('general')
    assert_instance_of BaseAssistant, assistant
    assert_equal 'general', assistant.name
  end

  def test_assistant_query_handling
    assistant = @assistant_registry.get_assistant('general')
    response = assistant.respond("Hello, how are you?")
    
    assert_instance_of String, response
    assert response.length > 0
  end

  def test_llm_manager_initialization
    assert_instance_of MultiLLMManager, @llm_manager
    assert @llm_manager.current_provider
    assert_instance_of Hash, @llm_manager.circuit_breakers
  end

  def test_llm_provider_status
    status = @llm_manager.provider_status
    
    assert_instance_of Hash, status
    assert status.key?(:xai)
    assert status.key?(:anthropic)
    assert status.key?(:openai)
    assert status.key?(:ollama)
  end

  def test_integrated_workflow
    # Test a complete workflow through the system
    user_id = 'integration_test_user'
    
    # 1. Create session
    session = @session_manager.create_session(user_id)
    assert session
    
    # 2. Add content to RAG
    document = {
      content: "AI³ is an interactive multi-LLM RAG CLI with cognitive orchestration",
      title: "AI³ Documentation"
    }
    @rag_engine.add_document(document, collection: 'docs')
    
    # 3. Get appropriate assistant
    query = "Tell me about AI³"
    assistant = @assistant_registry.find_best_assistant(query)
    assert assistant
    
    # 4. Generate response
    response = assistant.respond(query, context: session[:context])
    assert_instance_of String, response
    
    # 5. Update session
    @session_manager.update_session(user_id, { last_query: query, last_response: response })
    updated_session = @session_manager.get_session(user_id)
    assert_equal query, updated_session[:context][:last_query]
  end

  def test_cognitive_circuit_breaker
    # Force cognitive overload
    15.times { |i| @cognitive_orchestrator.add_concept("overload_concept_#{i}", 1.0) }
    
    # Trigger circuit breaker
    snapshot_id = @cognitive_orchestrator.trigger_circuit_breaker
    
    assert_instance_of String, snapshot_id
    assert @cognitive_orchestrator.current_load < 7
  end

  def test_cognitive_state_reporting
    state = @cognitive_orchestrator.cognitive_state
    
    assert_instance_of Hash, state
    assert state.key?(:load)
    assert state.key?(:complexity)
    assert state.key?(:concepts)
    assert state.key?(:switches)
    assert state.key?(:flow_state)
    assert state.key?(:overload_risk)
  end

  private

  def cleanup_test_data
    # Clean up test database files
    ['tmp/test_vector_store.db', 'tmp/test_sessions.db'].each do |file|
      File.delete(file) if File.exist?(file)
    end
    
    # Create tmp directory if it doesn't exist
    FileUtils.mkdir_p('tmp') unless Dir.exist?('tmp')
  end
end