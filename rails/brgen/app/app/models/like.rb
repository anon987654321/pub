class Like < ApplicationRecord
  belongs_to :user
  belongs_to :likeable, polymorphic: true
  
  validates :user_id, presence: true
  validates :likeable_id, presence: true
  validates :user_id, uniqueness: { scope: [:likeable_type, :likeable_id] }
  
  after_create :create_like_notification
  after_destroy :remove_like_notification
  
private

  # Master.json compliant methods (≤20 lines each)
  def create_like_notification
    return if likeable.user == user
    
    Notification.create!(
      user: likeable.user,
      message: create_notification_message,
      notification_type: 'like'
    )
  end
  
  def remove_like_notification
    return if likeable.user == user
    
    Notification.find_by(
      user: likeable.user,
      notification_type: 'like',
      message: create_notification_message
    )&.destroy
  end
  
  def create_notification_message
    "#{user.full_name_or_email} liked your #{likeable_type.downcase}"
  end
end
