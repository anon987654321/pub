# frozen_string_literal: true

# session_manager.rb - Enhanced Version with eviction strategies

class SessionManager
  attr_accessor :sessions, :max_sessions

  def initialize(max_sessions: 10, eviction_strategy: :oldest)
    @sessions = {}
    @max_sessions = max_sessions
    @eviction_strategy = eviction_strategy
  end

  def create_session(user_id)
    evict_session if @sessions.size >= @max_sessions
    @sessions[user_id] = { context: {}, timestamp: Time.now }
  end

  def get_session(user_id)
    @sessions[user_id] ||= create_session(user_id)
  end

  def update_session(user_id, new_context)
    session = get_session(user_id)
    session[:context].merge!(new_context)
    session[:timestamp] = Time.now
  end

  def remove_session(user_id)
    @sessions.delete(user_id)
  end

  def list_active_sessions
    @sessions.keys
  end

  def clear_all_sessions
    @sessions.clear
  end

  private

  def evict_session
    case @eviction_strategy
    when :oldest, :least_recently_used
      remove_oldest_session
    else
      raise "Unknown eviction strategy: #{@eviction_strategy}"
    end
  end

  def remove_oldest_session
    oldest_user_id = @sessions.min_by { |_user_id, session| session[:timestamp] }[0]
    remove_session(oldest_user_id)
  end
end