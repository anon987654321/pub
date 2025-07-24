class Follow < ApplicationRecord
  belongs_to :follower, class_name: 'User'
  belongs_to :followed, class_name: 'User'
  
  validates :follower_id, presence: true
  validates :followed_id, presence: true
  validates :follower_id, uniqueness: { scope: :followed_id }
  
  validate :cannot_follow_self
  
  after_create :create_follow_notification
  after_destroy :remove_follow_notification
  
private

  # Master.json compliant methods (≤20 lines each)
  def cannot_follow_self
    return unless follower_id == followed_id
    errors.add(:followed, "cannot follow yourself")
  end
  
  def create_follow_notification
    Notification.create!(
      user: followed,
      message: "#{follower.full_name_or_email} started following you",
      notification_type: 'follow'
    )
  end
  
  def remove_follow_notification
    Notification.find_by(
      user: followed,
      notification_type: 'follow',
      message: "#{follower.full_name_or_email} started following you"
    )&.destroy
  end
end
