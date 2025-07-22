class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  # Associations following master.json compliance
  has_many :posts, dependent: :destroy
  has_many :comments, dependent: :destroy
  has_many :likes, dependent: :destroy
  has_many :notifications, dependent: :destroy
  
  # Direct messaging associations
  has_many :sent_messages, class_name: 'DirectMessage', 
           foreign_key: :sender_id, dependent: :destroy
  has_many :received_messages, class_name: 'DirectMessage', 
           foreign_key: :recipient_id, dependent: :destroy

  # Following associations
  has_many :following_relationships, class_name: 'Follow',
           foreign_key: :follower_id, dependent: :destroy
  has_many :follower_relationships, class_name: 'Follow', 
           foreign_key: :followed_id, dependent: :destroy
  
  has_many :following, through: :following_relationships, source: :followed
  has_many :followers, through: :follower_relationships, source: :follower

  # Profile enhancements
  validates :email, presence: true, uniqueness: true
  
  # Master.json compliant methods (≤20 lines each)
  def full_name_or_email
    email
  end
  
  def unread_messages_count
    received_messages.where(read_at: nil).count
  end
  
  def unread_notifications_count
    notifications.where(read_at: nil).count
  end
  
  def following?(other_user)
    following.include?(other_user)
  end
  
  def follow!(other_user)
    following_relationships.create!(followed: other_user)
  end
  
  def unfollow!(other_user)
    following_relationships.find_by(followed: other_user)&.destroy
  end
end
