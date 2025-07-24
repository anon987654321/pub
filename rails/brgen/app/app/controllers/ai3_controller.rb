# frozen_string_literal: true

# AI3 Controller - Provides AI assistant functionality to the Rails application
class Ai3Controller < ApplicationController
  before_action :authenticate_user!
  before_action :set_ai3_service
  before_action :set_assistant_name, only: [:show, :query, :capabilities]
  
  # GET /ai3
  # Show AI3 dashboard with available assistants
  def index
    @assistants = @ai3_service.available_assistants
    @health_status = @ai3_service.health_check
    
    respond_to do |format|
      format.html
      format.json { render json: { assistants: @assistants, health: @health_status } }
    end
  end
  
  # GET /ai3/:assistant_name
  # Show specific assistant interface
  def show
    @assistant_capabilities = @ai3_service.assistant_capabilities(@assistant_name)
    @conversation_history = @ai3_service.conversation_history(limit: 20)
    
    respond_to do |format|
      format.html
      format.json { render json: { assistant: @assistant_capabilities, history: @conversation_history } }
    end
  end
  
  # POST /ai3/:assistant_name/query
  # Send query to specific assistant
  def query
    query_text = params.require(:query)
    context = params[:context] || {}
    
    result = @ai3_service.query_assistant(@assistant_name, query_text, context: context)
    
    respond_to do |format|
      format.html do
        if result[:success]
          flash[:notice] = "Query processed successfully"
          redirect_to ai3_path(@assistant_name)
        else
          flash[:alert] = result[:error]
          redirect_back(fallback_location: ai3_path(@assistant_name))
        end
      end
      
      format.json { render json: result }
      
      format.turbo_stream do
        if result[:success]
          render turbo_stream: turbo_stream.append(
            "ai3-responses",
            partial: "ai3/response",
            locals: { response: result[:data], assistant: @assistant_name }
          )
        else
          render turbo_stream: turbo_stream.replace(
            "ai3-error",
            partial: "shared/error",
            locals: { message: result[:error] }
          )
        end
      end
    end
  rescue ActionController::ParameterMissing => e
    handle_parameter_error(e)
  end
  
  # GET /ai3/:assistant_name/capabilities
  # Get assistant capabilities and documentation
  def capabilities
    @capabilities = @ai3_service.assistant_capabilities(@assistant_name)
    
    respond_to do |format|
      format.html
      format.json { render json: @capabilities }
    end
  end
  
  # GET /ai3/search
  # Search knowledge base
  def search
    query = params[:q]
    filters = params[:filters] || {}
    
    if query.present?
      @results = @ai3_service.search_knowledge(query, filters: filters)
    else
      @results = { success: false, error: "Query parameter required" }
    end
    
    respond_to do |format|
      format.html
      format.json { render json: @results }
    end
  end
  
  # POST /ai3/knowledge
  # Add content to knowledge base
  def add_knowledge
    content = params.require(:content)
    metadata = params[:metadata] || {}
    
    result = @ai3_service.add_knowledge(content, metadata: metadata)
    
    respond_to do |format|
      format.html do
        if result[:success]
          flash[:notice] = "Knowledge added successfully"
        else
          flash[:alert] = result[:error]
        end
        redirect_back(fallback_location: ai3_index_path)
      end
      
      format.json { render json: result }
    end
  rescue ActionController::ParameterMissing => e
    handle_parameter_error(e)
  end
  
  # GET /ai3/history
  # Get conversation history
  def history
    limit = params[:limit]&.to_i || 50
    @history = @ai3_service.conversation_history(limit: limit)
    
    respond_to do |format|
      format.html
      format.json { render json: { history: @history } }
    end
  end
  
  # GET /ai3/health
  # System health check
  def health
    @health_status = @ai3_service.health_check
    
    respond_to do |format|
      format.html
      format.json { render json: @health_status }
    end
  end
  
  private
  
  def set_ai3_service
    # Initialize AI3 service with current user and tenant context
    current_community = current_tenant if defined?(current_tenant)
    @ai3_service = Ai3Service.new(user: current_user, community: current_community)
  end
  
  def set_assistant_name
    @assistant_name = params[:assistant_name] || params[:id]
    
    unless @assistant_name.present?
      respond_to do |format|
        format.html { redirect_to ai3_index_path, alert: "Assistant name required" }
        format.json { render json: { error: "Assistant name required" }, status: :bad_request }
      end
    end
  end
  
  def handle_parameter_error(error)
    respond_to do |format|
      format.html do
        flash[:alert] = "Missing required parameter: #{error.param}"
        redirect_back(fallback_location: ai3_index_path)
      end
      format.json { render json: { error: error.message }, status: :bad_request }
    end
  end
end