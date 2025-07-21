class DirectMessage < ApplicationRecord
  belongs_to :sender, class_name: 'User'
  belongs_to :recipient, class_name: 'User'
  
  validates :content, presence: true, length: { minimum: 1, maximum: 2000 }
  validates :sender_id, presence: true
  validates :recipient_id, presence: true
  
  scope :unread_messages, -> { where(read_at: nil) }
  scope :conversation_between, ->(user1, user2) {
    where(
      "(sender_id = ? AND recipient_id = ?) OR (sender_id = ? AND recipient_id = ?)",
      user1.id, user2.id, user2.id, user1.id
    ).order(:created_at)
  }
  
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
  
  def conversation_partner(current_user)
    current_user == sender ? recipient : sender
  end
end
