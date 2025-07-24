# frozen_string_literal: true

# AI3 Integration Service for Rails Application
# Provides unified interface to AI3 assistant ecosystem
class Ai3Service
  include CableReady::Broadcaster
  
  attr_reader :session_manager, :llm_manager, :rag_engine
  
  def initialize(user: nil, community: nil)
    @user = user
    @community = community
    @session_id = generate_session_id
    setup_ai3_components
  end
  
  # Get available assistants
  def available_assistants
    @assistant_registry ||= load_assistant_registry
    @assistant_registry.list_assistants
  end
  
  # Query an assistant with context
  def query_assistant(assistant_name, query, context: {})
    assistant = find_assistant(assistant_name)
    return error_response("Assistant not found: #{assistant_name}") unless assistant
    
    # Add Rails context
    enhanced_context = context.merge(
      user_id: @user&.id,
      community_id: @community&.id,
      session_id: @session_id,
      rails_env: Rails.env
    )
    
    begin
      response = assistant.process_query(query, enhanced_context)
      log_interaction(assistant_name, query, response)
      
      # Broadcast real-time update if user present
      broadcast_assistant_response(response) if @user
      
      success_response(response)
    rescue StandardError => e
      Rails.logger.error "AI3 Assistant Error: #{e.message}"
      error_response("Processing failed: #{e.message}")
    end
  end
  
  # Get conversation history
  def conversation_history(limit: 50)
    @session_manager.get_history(@session_id, limit: limit)
  end
  
  # Search knowledge base
  def search_knowledge(query, filters: {})
    return error_response("RAG engine not available") unless @rag_engine
    
    # Apply tenant filtering
    tenant_filters = filters.merge(
      community_id: @community&.id
    ).compact
    
    @rag_engine.search(query, filters: tenant_filters)
  end
  
  # Add knowledge to base
  def add_knowledge(content, metadata: {})
    return error_response("RAG engine not available") unless @rag_engine
    
    # Add tenant context to metadata
    enhanced_metadata = metadata.merge(
      community_id: @community&.id,
      user_id: @user&.id,
      created_at: Time.current.iso8601
    ).compact
    
    @rag_engine.add_document(content, metadata: enhanced_metadata)
  end
  
  # Get assistant capabilities
  def assistant_capabilities(assistant_name)
    assistant = find_assistant(assistant_name)
    return {} unless assistant
    
    {
      name: assistant_name,
      description: assistant.description,
      supported_queries: assistant.supported_query_types,
      example_prompts: assistant.example_prompts,
      specialized_for: assistant.specializations
    }
  end
  
  # Health check for AI3 system
  def health_check
    {
      status: 'operational',
      assistants_loaded: available_assistants.count,
      session_manager: @session_manager&.healthy? || false,
      llm_manager: @llm_manager&.healthy? || false,
      rag_engine: @rag_engine&.available? || false,
      last_check: Time.current.iso8601
    }
  end
  
  private
  
  def setup_ai3_components
    ai3_lib_path = Rails.root.join('lib', 'integrations', 'ai3', 'lib')
    return unless ai3_lib_path.exist?
    
    # Load AI3 components
    require_ai3_dependencies
    
    @session_manager = initialize_session_manager
    @llm_manager = initialize_llm_manager
    @rag_engine = initialize_rag_engine
    @assistant_registry = load_assistant_registry
  rescue StandardError => e
    Rails.logger.warn "AI3 setup failed: #{e.message}"
  end
  
  def require_ai3_dependencies
    ai3_lib_path = Rails.root.join('lib', 'integrations', 'ai3', 'lib')
    
    # Load core AI3 components
    [
      'enhanced_session_manager',
      'multi_llm_manager', 
      'rag_engine',
      'assistant_registry',
      'cognitive_orchestrator'
    ].each do |component|
      component_path = ai3_lib_path.join("#{component}.rb")
      require component_path.to_s if component_path.exist?
    end
  end
  
  def initialize_session_manager
    return nil unless defined?(EnhancedSessionManager)
    
    EnhancedSessionManager.new(
      redis_url: Rails.application.credentials.redis_url || "redis://localhost:6379/2",
      session_ttl: 24.hours.to_i
    )
  end
  
  def initialize_llm_manager
    return nil unless defined?(MultiLlmManager)
    
    MultiLlmManager.new(
      openai_key: Rails.application.credentials.openai_api_key,
      claude_key: Rails.application.credentials.claude_api_key,
      replicate_key: Rails.application.credentials.replicate_api_key
    )
  end
  
  def initialize_rag_engine
    return nil unless defined?(RagEngine)
    
    RagEngine.new(
      weaviate_url: Rails.application.credentials.weaviate_url || "http://localhost:8080",
      embedding_model: "text-embedding-ada-002"
    )
  end
  
  def load_assistant_registry
    return {} unless defined?(AssistantRegistry)
    
    assistants_path = Rails.root.join('lib', 'integrations', 'ai3', 'assistants')
    AssistantRegistry.new(assistants_path: assistants_path.to_s)
  end
  
  def find_assistant(name)
    return nil unless @assistant_registry
    
    @assistant_registry.get_assistant(name.to_s.downcase)
  end
  
  def generate_session_id
    "#{@user&.id || 'anon'}_#{@community&.id || 'global'}_#{SecureRandom.hex(8)}"
  end
  
  def log_interaction(assistant_name, query, response)
    Rails.logger.info "AI3 Interaction: #{assistant_name} - Query: #{query[0..100]}... Response: #{response.to_s[0..100]}..."
    
    # Store in session history if available
    @session_manager&.store_interaction(@session_id, {
      assistant: assistant_name,
      query: query,
      response: response,
      timestamp: Time.current.iso8601,
      user_id: @user&.id,
      community_id: @community&.id
    })
  end
  
  def broadcast_assistant_response(response)
    return unless @user
    
    cable_ready
      .insert_adjacent_html(
        selector: "#ai3-responses", 
        position: "beforeend",
        html: render_response_html(response)
      )
      .broadcast_to(@user, identifier: "Ai3Channel")
  end
  
  def render_response_html(response)
    # Simple HTML rendering - can be enhanced with proper view templates
    content = case response
              when Hash
                response[:content] || response['content'] || response.to_s
              else
                response.to_s
              end
    
    "<div class='ai3-response' data-timestamp='#{Time.current.iso8601}'>#{ERB::Util.html_escape(content)}</div>"
  end
  
  def success_response(data)
    {
      success: true,
      data: data,
      timestamp: Time.current.iso8601
    }
  end
  
  def error_response(message)
    {
      success: false,
      error: message,
      timestamp: Time.current.iso8601
    }
  end
end