class UsersController < ApplicationController
  before_action :authenticate_user!, except: [:show]
  before_action :set_user, only: [:show, :edit, :update, :follow, :unfollow]
  before_action :authorize_user!, only: [:edit, :update]
  
  # Master.json compliant method (≤20 lines)
  def show
    @pagy, @posts = pagy(@user.posts.published_posts
                              .includes(:likes, :comments)
                              .recent_posts, items: 10)
    
    @followers_count = @user.followers.count
    @following_count = @user.following.count
    @posts_count = @user.posts.published_posts.count
  end
  
  # Master.json compliant method (≤20 lines)
  def edit
  end
  
  # Master.json compliant method (≤20 lines)
  def update
    if @user.update(user_params)
      redirect_to @user, notice: 'Profile updated successfully.'
    else
      render :edit, status: :unprocessable_entity
    end
  end
  
  # Master.json compliant method (≤20 lines)
  def follow
    if current_user.follow!(@user)
      redirect_back(fallback_location: @user, notice: "Now following #{@user.full_name_or_email}")
    else
      redirect_back(fallback_location: @user, alert: 'Unable to follow user.')
    end
  end
  
  # Master.json compliant method (≤20 lines)
  def unfollow
    if current_user.unfollow!(@user)
      redirect_back(fallback_location: @user, notice: "Unfollowed #{@user.full_name_or_email}")
    else
      redirect_back(fallback_location: @user, alert: 'Unable to unfollow user.')
    end
  end

private

  # Master.json compliant method (≤20 lines)
  def set_user
    @user = User.find(params[:id])
  end
  
  # Master.json compliant method (≤20 lines)
  def authorize_user!
    unless @user == current_user
      redirect_to @user, alert: 'Not authorized to edit this profile.'
    end
  end
  
  # Master.json compliant method (≤20 lines)
  def user_params
    params.require(:user).permit(:first_name, :last_name, :bio)
  end
end
