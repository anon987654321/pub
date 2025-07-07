# Enhanced Session Manager - Migrated from ai3_old
# Preserves LRU eviction strategy with cognitive load awareness

class EnhancedSessionManager
  attr_accessor :sessions, :max_sessions, :eviction_strategy

  def initialize(max_sessions: 10, eviction_strategy: :oldest)
    @sessions = {}
    @max_sessions = max_sessions
    @eviction_strategy = eviction_strategy
  end

  # Create a new session with timestamp tracking
  def create_session(user_id)
    evict_session if @sessions.size >= @max_sessions
    @sessions[user_id] = { context: {}, timestamp: Time.now }
  end

  # Get or create session for user
  def get_session(user_id)
    @sessions[user_id] ||= create_session(user_id)
  end

  # Update session with context merging capabilities
  def update_session(user_id, new_context)
    session = get_session(user_id)
    session[:context].merge!(new_context)
    session[:timestamp] = Time.now
  end

  # Remove specific session
  def remove_session(user_id)
    @sessions.delete(user_id)
  end

  # List all active session IDs
  def list_active_sessions
    @sessions.keys
  end

  # Clear all sessions for cognitive reset
  def clear_all_sessions
    @sessions.clear
  end

  # Get session count for cognitive load monitoring
  def session_count
    @sessions.size
  end

  # Get cognitive load percentage
  def cognitive_load_percentage
    (@sessions.size.to_f / @max_sessions * 100).round(2)
  end

  private

  # Evict session based on strategy
  def evict_session
    case @eviction_strategy
    when :oldest, :least_recently_used
      remove_oldest_session
    else
      raise "Unknown eviction strategy: #{@eviction_strategy}"
    end
  end

  # Remove the oldest session by timestamp
  def remove_oldest_session
    return if @sessions.empty?
    
    oldest_user_id = @sessions.min_by { |_user_id, session| session[:timestamp] }[0]
    remove_session(oldest_user_id)
  end
end