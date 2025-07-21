class Post < ApplicationRecord
  belongs_to :user
  has_many :comments, dependent: :destroy
  has_many :likes, as: :likeable, dependent: :destroy
  has_one_attached :featured_image
  
  validates :title, presence: true, length: { minimum: 5, maximum: 200 }
  validates :content, presence: true, length: { minimum: 10 }
  validates :published, inclusion: { in: [true, false] }
  
  scope :published_posts, -> { where(published: true) }
  scope :recent_posts, -> { order(created_at: :desc) }
  scope :by_user, ->(user) { where(user: user) }
  
  include PgSearch::Model
  pg_search_scope :search_by_content, 
    against: [:title, :content],
    using: { tsearch: { prefix: true } }
  
  # Master.json compliant methods (≤20 lines each)
  def likes_count
    likes.count
  end
  
  def comments_count
    comments.count
  end
  
  def liked_by?(current_user)
    return false unless current_user
    likes.exists?(user: current_user)
  end
  
  def summary_text
    content.truncate(150)
  end
  
  def reading_time_minutes
    words = content.split.size
    (words / 200.0).ceil
  end
end
