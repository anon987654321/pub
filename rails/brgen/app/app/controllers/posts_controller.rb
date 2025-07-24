class PostsController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show]
  before_action :set_post, only: [:show, :edit, :update, :destroy, :like, :unlike]
  before_action :authorize_user!, only: [:edit, :update, :destroy]
  
  # Master.json compliant method (≤20 lines)
  def index
    posts_query = Post.published_posts
                      .includes(:user, :likes, :comments)
                      .recent_posts
    
    if params[:search].present?
      posts_query = posts_query.search_by_content(params[:search])
    end
    
    @pagy, @posts = pagy(posts_query, items: 10)
    
    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end
  
  # Master.json compliant method (≤20 lines)
  def show
    @comment = Comment.new
    @comments = @post.comments
                     .root_comments
                     .includes(:user, :children, :likes)
    
    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end
  
  # Master.json compliant method (≤20 lines)
  def new
    @post = current_user.posts.build
  end
  
  # Master.json compliant method (≤20 lines)
  def create
    @post = current_user.posts.build(post_params)
    
    if @post.save
      redirect_to @post, notice: 'Post created successfully.'
    else
      render :new, status: :unprocessable_entity
    end
  end
  
  # Master.json compliant method (≤20 lines)
  def edit
  end
  
  # Master.json compliant method (≤20 lines)
  def update
    if @post.update(post_params)
      redirect_to @post, notice: 'Post updated successfully.'
    else
      render :edit, status: :unprocessable_entity
    end
  end
  
  # Master.json compliant method (≤20 lines)
  def destroy
    @post.destroy
    redirect_to posts_path, notice: 'Post deleted successfully.'
  end
  
  # Master.json compliant method (≤20 lines)
  def like
    @like = @post.likes.build(user: current_user)
    
    if @like.save
      render turbo_stream: turbo_stream.replace(
        "post_#{@post.id}_likes", 
        partial: 'posts/likes', 
        locals: { post: @post }
      )
    end
  end
  
  # Master.json compliant method (≤20 lines)
  def unlike
    @like = @post.likes.find_by(user: current_user)
    @like&.destroy
    
    render turbo_stream: turbo_stream.replace(
      "post_#{@post.id}_likes", 
      partial: 'posts/likes', 
      locals: { post: @post }
    )
  end

private

  # Master.json compliant method (≤20 lines)
  def set_post
    @post = Post.find(params[:id])
  end
  
  # Master.json compliant method (≤20 lines)
  def authorize_user!
    redirect_to posts_path, alert: 'Not authorized.' unless @post.user == current_user
  end
  
  # Master.json compliant method (≤20 lines)
  def post_params
    params.require(:post).permit(:title, :content, :published, :featured_image)
  end
end
