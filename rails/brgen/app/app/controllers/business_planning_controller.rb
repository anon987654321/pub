# frozen_string_literal: true

# Business Planning Controller - Lean Canvas, OKRs, Stakeholder Mapping, Design Thinking
class BusinessPlanningController < ApplicationController
  before_action :authenticate_user!
  before_action :set_planning_service
  before_action :set_plan_type, only: [:show, :create, :update, :destroy]
  
  # GET /business_planning
  # Dashboard with all business planning tools
  def index
    @all_plans = @planning_service.get_all_plans
    @insights = @planning_service.generate_business_insights
    
    respond_to do |format|
      format.html
      format.json { render json: { plans: @all_plans, insights: @insights } }
    end
  end
  
  # GET /business_planning/lean_canvas
  # Lean Canvas management
  def lean_canvas
    @canvases = @planning_service.get_all_plans("lean_canvas")
    
    respond_to do |format|
      format.html
      format.json { render json: @canvases }
    end
  end
  
  # POST /business_planning/lean_canvas
  # Create new lean canvas
  def create_lean_canvas
    canvas_params = params.require(:lean_canvas).permit(
      :unique_value_proposition, :unfair_advantage,
      problem: [], solution: [], customer_segments: [],
      key_metrics: [], channels: [], cost_structure: [], revenue_streams: []
    )
    
    result = @planning_service.create_lean_canvas(canvas_params.to_h)
    
    respond_to do |format|
      format.html do
        if result[:success]
          flash[:notice] = "Lean Canvas created successfully"
          redirect_to lean_canvas_business_planning_path
        else
          flash[:alert] = result[:error]
          redirect_back(fallback_location: lean_canvas_business_planning_path)
        end
      end
      
      format.json { render json: result }
      
      format.turbo_stream do
        if result[:success]
          render turbo_stream: turbo_stream.prepend(
            "lean-canvases",
            partial: "business_planning/lean_canvas_card",
            locals: { canvas: result[:data] }
          )
        else
          render turbo_stream: turbo_stream.replace(
            "form-errors",
            partial: "shared/error",
            locals: { message: result[:error] }
          )
        end
      end
    end
  end
  
  # PATCH /business_planning/lean_canvas/:id
  # Update existing lean canvas
  def update_lean_canvas
    canvas_id = params[:id]
    updates = params.require(:lean_canvas).permit(
      :unique_value_proposition, :unfair_advantage,
      problem: [], solution: [], customer_segments: [],
      key_metrics: [], channels: [], cost_structure: [], revenue_streams: []
    ).to_h
    
    result = @planning_service.update_lean_canvas(canvas_id, updates)
    
    respond_to do |format|
      format.html do
        if result[:success]
          flash[:notice] = "Lean Canvas updated successfully"
        else
          flash[:alert] = result[:error]
        end
        redirect_to lean_canvas_business_planning_path
      end
      
      format.json { render json: result }
    end
  end
  
  # GET /business_planning/okrs
  # OKR management dashboard
  def okrs
    @okrs = @planning_service.get_all_plans("okr")
    
    respond_to do |format|
      format.html
      format.json { render json: @okrs }
    end
  end
  
  # POST /business_planning/okrs
  # Create new OKR
  def create_okr
    objective = params.require(:okr)[:objective]
    key_results = params.require(:okr)[:key_results]&.values || []
    
    # Parse key results from form data
    parsed_key_results = key_results.map do |kr|
      {
        description: kr[:description],
        target_value: kr[:target_value].to_f,
        current_value: kr[:current_value]&.to_f || 0,
        unit: kr[:unit] || "percentage"
      }
    end
    
    result = @planning_service.create_okr(objective, parsed_key_results)
    
    respond_to do |format|
      format.html do
        if result[:success]
          flash[:notice] = "OKR created successfully"
          redirect_to okrs_business_planning_path
        else
          flash[:alert] = result[:error]
          redirect_back(fallback_location: okrs_business_planning_path)
        end
      end
      
      format.json { render json: result }
    end
  end
  
  # PATCH /business_planning/okrs/:okr_id/progress
  # Update OKR progress
  def update_okr_progress
    okr_id = params[:okr_id]
    key_result_id = params[:key_result_id]
    new_value = params[:new_value]
    
    result = @planning_service.update_okr_progress(okr_id, key_result_id, new_value)
    
    respond_to do |format|
      format.html do
        if result[:success]
          flash[:notice] = "Progress updated successfully"
        else
          flash[:alert] = result[:error]
        end
        redirect_to okrs_business_planning_path
      end
      
      format.json { render json: result }
      
      format.turbo_stream do
        if result[:success]
          render turbo_stream: turbo_stream.replace(
            "okr-#{okr_id}",
            partial: "business_planning/okr_card",
            locals: { okr: result[:data] }
          )
        end
      end
    end
  end
  
  # GET /business_planning/stakeholders
  # Stakeholder mapping
  def stakeholders
    @stakeholder_maps = @planning_service.get_all_plans("stakeholder_map")
    
    respond_to do |format|
      format.html
      format.json { render json: @stakeholder_maps }
    end
  end
  
  # POST /business_planning/stakeholders
  # Create stakeholder map
  def create_stakeholders
    stakeholders_data = params.require(:stakeholder_map)[:stakeholders]&.values || []
    
    parsed_stakeholders = stakeholders_data.map do |stakeholder|
      {
        name: stakeholder[:name],
        role: stakeholder[:role],
        influence: stakeholder[:influence],
        interest: stakeholder[:interest],
        engagement_strategy: stakeholder[:engagement_strategy],
        contact_info: stakeholder[:contact_info] || {},
        notes: stakeholder[:notes]
      }
    end
    
    result = @planning_service.create_stakeholder_map(parsed_stakeholders)
    
    respond_to do |format|
      format.html do
        if result[:success]
          flash[:notice] = "Stakeholder map created successfully"
          redirect_to stakeholders_business_planning_path
        else
          flash[:alert] = result[:error]
          redirect_back(fallback_location: stakeholders_business_planning_path)
        end
      end
      
      format.json { render json: result }
    end
  end
  
  # GET /business_planning/design_thinking
  # Design thinking sessions
  def design_thinking
    @sessions = @planning_service.get_all_plans("design_thinking")
    
    respond_to do |format|
      format.html
      format.json { render json: @sessions }
    end
  end
  
  # POST /business_planning/design_thinking
  # Start new design thinking session
  def create_design_thinking
    challenge_statement = params.require(:design_thinking)[:challenge_statement]
    
    result = @planning_service.initiate_design_thinking_session(challenge_statement)
    
    respond_to do |format|
      format.html do
        if result[:success]
          flash[:notice] = "Design thinking session started"
          redirect_to design_thinking_business_planning_path
        else
          flash[:alert] = result[:error]
          redirect_back(fallback_location: design_thinking_business_planning_path)
        end
      end
      
      format.json { render json: result }
    end
  end
  
  # PATCH /business_planning/design_thinking/:session_id
  # Update design thinking phase
  def update_design_thinking
    session_id = params[:session_id]
    phase = params[:phase]
    updates = params[:updates]&.to_unsafe_h || {}
    
    result = @planning_service.update_design_thinking_phase(session_id, phase, updates)
    
    respond_to do |format|
      format.html do
        if result[:success]
          flash[:notice] = "Design thinking session updated"
        else
          flash[:alert] = result[:error]
        end
        redirect_to design_thinking_business_planning_path
      end
      
      format.json { render json: result }
    end
  end
  
  # GET /business_planning/insights
  # Business insights and analytics
  def insights
    @insights = @planning_service.generate_business_insights
    
    respond_to do |format|
      format.html
      format.json { render json: @insights }
    end
  end
  
  # POST /business_planning/trading_integration
  # Integrate with Norwegian hedge fund trading strategies
  def trading_integration
    strategy_params = params.permit(:strategy_type, :risk_level, :allocation_percentage).to_h
    
    result = @planning_service.integrate_trading_strategies(strategy_params)
    
    respond_to do |format|
      format.html do
        if result[:success]
          flash[:notice] = "Trading strategy integrated successfully"
          redirect_to insights_business_planning_path
        else
          flash[:alert] = result[:error]
          redirect_back(fallback_location: insights_business_planning_path)
        end
      end
      
      format.json { render json: result }
    end
  end
  
  private
  
  def set_planning_service
    current_community = current_tenant if defined?(current_tenant)
    @planning_service = BusinessPlanningService.new(user: current_user, community: current_community)
  end
  
  def set_plan_type
    @plan_type = params[:plan_type]
  end
end