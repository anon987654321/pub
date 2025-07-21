class HomeController < ApplicationController
  before_action :authenticate_user!, except: [:index]
  
  # Master.json compliant method (≤20 lines)
  def index
    if user_signed_in?
      load_dashboard_content
    else
      load_public_content
    end
  end

private

  # Master.json compliant method (≤20 lines)
  def load_dashboard_content
    @recent_posts = current_user.following
                                .joins(:posts)
                                .includes(:posts)
                                .merge(Post.published_posts.recent_posts)
                                .limit(20)
    @trending_posts = Post.published_posts
                          .joins(:likes)
                          .group('posts.id')
                          .order('COUNT(likes.id) DESC')
                          .limit(10)
  end
  
  # Master.json compliant method (≤20 lines)
  def load_public_content
    @recent_posts = Post.published_posts
                        .recent_posts
                        .includes(:user, :likes)
                        .limit(20)
    @trending_posts = Post.published_posts
                          .joins(:likes)
                          .group('posts.id')
                          .order('COUNT(likes.id) DESC')
                          .limit(10)
  end
end
