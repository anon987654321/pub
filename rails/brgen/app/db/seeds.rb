# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
#
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# Clear existing data in development
if Rails.env.development?
  puts "🧹 Cleaning up existing data..."
  Like.destroy_all
  Comment.destroy_all
  Post.destroy_all
  Follow.destroy_all
  Notification.destroy_all
  DirectMessage.destroy_all
  User.destroy_all
end

puts "🌱 Seeding the Brgen platform..."

# Create sample users
puts "👤 Creating users..."
users = []

# Create admin user
admin = User.create!(
  email: 'admin@brgen.com',
  password: 'password123',
  password_confirmation: 'password123'
)
users << admin

# Create regular users
5.times do |i|
  user = User.create!(
    email: "user#{i + 1}@example.com",
    password: 'password123',
    password_confirmation: 'password123'
  )
  users << user
end

puts "✅ Created #{users.count} users"

# Create sample posts
puts "📝 Creating posts..."
posts = []

users.each do |user|
  rand(2..4).times do |i|
    post = user.posts.create!(
      title: [
        "Welcome to Brgen - My First Post",
        "Building Modern Web Applications with Rails",
        "The Future of Social Networking",
        "Best Practices for Community Building",
        "How to Create Engaging Content",
        "Tips for Better User Experience",
        "Building Inclusive Online Communities"
      ].sample,
      content: [
        "This is my first post on Brgen! I'm excited to be part of this amazing community. Looking forward to sharing ideas and connecting with like-minded people.",
        "I've been working on some interesting projects lately and wanted to share my experiences. The tech community here seems really supportive and knowledgeable.",
        "Just discovered this platform and I'm impressed with the clean design and user-friendly interface. Great job to the development team!",
        "Has anyone here worked with Rails 7? I'm curious about the new features and how they compare to previous versions. Would love to hear your thoughts!",
        "Building community is more than just creating a platform - it's about fostering meaningful connections and encouraging authentic conversations."
      ].sample,
      published: true
    )
    posts << post
  end
end

puts "✅ Created #{posts.count} posts"

# Create sample comments
puts "💬 Creating comments..."
comments_count = 0

posts.each do |post|
  # Create root comments
  rand(1..3).times do
    commenting_user = users.sample
    comment = post.comments.create!(
      content: [
        "Great post! Thanks for sharing your insights.",
        "I completely agree with your points here.",
        "This is really helpful. I'll definitely try this approach.",
        "Interesting perspective! I hadn't thought about it that way.",
        "Thanks for taking the time to write this up."
      ].sample,
      user: commenting_user
    )
    comments_count += 1
    
    # Sometimes add a reply
    if rand < 0.3
      reply_user = users.sample
      comment.children.create!(
        content: [
          "Thanks for the feedback!",
          "Glad you found it useful.",
          "Feel free to ask if you have any questions.",
          "I appreciate your input on this."
        ].sample,
        user: reply_user,
        post: post
      )
      comments_count += 1
    end
  end
end

puts "✅ Created #{comments_count} comments"

# Create sample likes
puts "❤️ Creating likes..."
likes_count = 0

posts.each do |post|
  # Random users like posts
  liking_users = users.sample(rand(0..users.length - 1))
  liking_users.each do |user|
    post.likes.create!(user: user)
    likes_count += 1
  end
end

puts "✅ Created #{likes_count} likes"

# Create sample follows
puts "👥 Creating follows..."
follows_count = 0

users.each do |follower|
  # Each user follows 1-3 other users
  potential_follows = users - [follower]
  followed_users = potential_follows.sample(rand(1..3))
  
  followed_users.each do |followed|
    Follow.create!(
      follower: follower,
      followed: followed
    )
    follows_count += 1
  end
end

puts "✅ Created #{follows_count} follows"

puts ""
puts "🎉 Seeding completed successfully!"
puts "📊 Summary:"
puts "   👤 Users: #{User.count}"
puts "   📝 Posts: #{Post.count}"
puts "   💬 Comments: #{Comment.count}"
puts "   ❤️ Likes: #{Like.count}"
puts "   👥 Follows: #{Follow.count}"
puts ""
puts "🔐 Login credentials:"
puts "   Admin: admin@brgen.com / password123"
puts "   User: user1@example.com / password123"
puts "   (Users 1-5 all have password: password123)"
puts ""
puts "🚀 Ready to explore Brgen!"