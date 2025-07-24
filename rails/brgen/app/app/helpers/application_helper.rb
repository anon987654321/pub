module ApplicationHelper
  include Pagy::Frontend
  
  # Master.json compliant helper (≤20 lines)
  def flash_class(level)
    case level.to_s
    when 'notice' then 'alert-success'
    when 'alert' then 'alert-danger'
    when 'info' then 'alert-info'
    when 'warning' then 'alert-warning'
    else 'alert-primary'
    end
  end
  
  # Master.json compliant helper (≤20 lines)
  def time_ago_in_words_or_date(time)
    return 'never' unless time
    
    if time > 7.days.ago
      time_ago_in_words(time) + ' ago'
    else
      time.strftime('%B %d, %Y')
    end
  end
  
  # Master.json compliant helper (≤20 lines)
  def user_avatar(user, size: 40)
    content_tag :div, class: "user-avatar", style: "width: #{size}px; height: #{size}px;" do
      content_tag :span, user.full_name_or_email.first.upcase, 
                  class: "avatar-initial"
    end
  end
  
  # Master.json compliant helper (≤20 lines)
  def notification_icon(notification_type)
    icons = {
      'like' => 'heart',
      'follow' => 'user-plus', 
      'comment' => 'message-circle',
      'direct_message' => 'mail'
    }
    
    icon_name = icons[notification_type] || 'bell'
    content_tag :i, '', class: "icon icon-#{icon_name}", 'aria-hidden': true
  end
end
