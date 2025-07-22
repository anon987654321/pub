class Comment < ApplicationRecord
  belongs_to :user
  belongs_to :post
  has_many :likes, as: :likeable, dependent: :destroy
  
  # Threaded comments using closure_tree
  has_closure_tree order: 'created_at ASC'
  
  validates :content, presence: true, length: { minimum: 3, maximum: 1000 }
  
  scope :root_comments, -> { where(parent_id: nil) }
  scope :recent_comments, -> { order(created_at: :desc) }
  
  # Master.json compliant methods (≤20 lines each)
  def likes_count
    likes.count
  end
  
  def liked_by?(current_user)
    return false unless current_user
    likes.exists?(user: current_user)
  end
  
  def reply_depth
    depth
  end
  
  def can_reply?
    reply_depth < 5 # Limit nesting to 5 levels
  end
  
  def summary_text
    content.truncate(100)
  end
end
