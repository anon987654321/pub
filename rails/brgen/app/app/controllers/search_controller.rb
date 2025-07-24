class SearchController < ApplicationController
  # Master.json compliant method (≤20 lines)
  def index
    @query = params[:search]&.strip
    
    if @query.present?
      perform_search
    else
      initialize_empty_search
    end
    
    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end

private

  # Master.json compliant method (≤20 lines)
  def perform_search
    @posts = Post.published_posts
                 .includes(:user, :likes, :comments)
                 .search_by_content(@query)
                 .recent_posts
    
    @pagy, @posts = pagy(@posts, items: 10)
    @users = User.where("email ILIKE ?", "%#{@query}%").limit(5)
  end
  
  # Master.json compliant method (≤20 lines)
  def initialize_empty_search
    @posts = Post.none
    @users = User.none
    @pagy = nil
  end
end
