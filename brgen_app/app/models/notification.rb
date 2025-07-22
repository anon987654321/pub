class Notification < ApplicationRecord
  belongs_to :user
  
  validates :message, presence: true, length: { minimum: 3, maximum: 500 }
  validates :notification_type, presence: true
  validates :user_id, presence: true
  
  scope :unread_notifications, -> { where(read_at: nil) }
  scope :recent_notifications, -> { order(created_at: :desc) }
  scope :by_type, ->(type) { where(notification_type: type) }
  
  # Master.json compliant methods (≤20 lines each)
  def mark_as_read!
    update!(read_at: Time.current) unless read?
  end
  
  def read?
    read_at.present?
  end
  
  def unread?
    !read?
  end
  
  def time_since_created
    time_ago_in_words(created_at)
  end
end
