class CommentsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_post, only: [:create]
  before_action :set_comment, only: [:edit, :update, :destroy]
  before_action :authorize_user!, only: [:edit, :update, :destroy]
  
  # Master.json compliant method (≤20 lines)
  def create
    @comment = @post.comments.build(comment_params)
    @comment.user = current_user
    
    if @comment.save
      redirect_to @post, notice: 'Comment added successfully.'
    else
      @comments = @post.comments.root_comments.includes(:user, :children, :likes)
      render 'posts/show', status: :unprocessable_entity
    end
  end
  
  # Master.json compliant method (≤20 lines)
  def edit
  end
  
  # Master.json compliant method (≤20 lines)
  def update
    if @comment.update(comment_params)
      redirect_to @comment.post, notice: 'Comment updated successfully.'
    else
      render :edit, status: :unprocessable_entity
    end
  end
  
  # Master.json compliant method (≤20 lines)
  def destroy
    post = @comment.post
    @comment.destroy
    redirect_to post, notice: 'Comment deleted successfully.'
  end

private

  # Master.json compliant method (≤20 lines)
  def set_post
    @post = Post.find(params[:post_id])
  end
  
  # Master.json compliant method (≤20 lines)
  def set_comment
    @comment = Comment.find(params[:id])
  end
  
  # Master.json compliant method (≤20 lines)
  def authorize_user!
    unless @comment.user == current_user || current_user.admin?
      redirect_to @comment.post, alert: 'Not authorized.'
    end
  end
  
  # Master.json compliant method (≤20 lines)
  def comment_params
    params.require(:comment).permit(:content, :parent_id)
  end
end
