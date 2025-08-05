# frozen_string_literal: true

# session_manager.rb - Enhanced Version with LRU eviction strategies

class SessionManager
  attr_accessor :sessions, :max_sessions

  def initialize(max_sessions: 10, eviction_strategy: :lru)
    @sessions = {}
    @max_sessions = max_sessions
    @eviction_strategy = eviction_strategy
    @access_order = [] # Track access order for LRU
  end

  def create_session(user_id)
    evict_session if @sessions.size >= @max_sessions
    @sessions[user_id] = { 
      context: {}, 
      timestamp: Time.now,
      last_accessed: Time.now,
      access_count: 0
    }
    @access_order << user_id
  end

  def get_session(user_id)
    if @sessions[user_id]
      # Update access tracking for LRU
      @sessions[user_id][:last_accessed] = Time.now
      @sessions[user_id][:access_count] += 1
      
      # Move to end of access order
      @access_order.delete(user_id)
      @access_order << user_id
    else
      create_session(user_id)
    end
    
    @sessions[user_id]
  end

  def update_session(user_id, new_context)
    session = get_session(user_id)
    session[:context].merge!(new_context)
    session[:timestamp] = Time.now
    session[:last_accessed] = Time.now
  end

  def remove_session(user_id)
    @sessions.delete(user_id)
    @access_order.delete(user_id)
  end

  def persist_session(user_id, storage_path = 'data/sessions')
    session = @sessions[user_id]
    return false unless session
    
    require 'fileutils'
    require 'json'
    
    FileUtils.mkdir_p(storage_path)
    File.write("#{storage_path}/#{user_id}.json", session.to_json)
    true
  end

  def restore_session(user_id, storage_path = 'data/sessions')
    require 'json'
    
    session_file = "#{storage_path}/#{user_id}.json"
    return false unless File.exist?(session_file)
    
    session_data = JSON.parse(File.read(session_file), symbolize_names: true)
    
    # Convert timestamp strings back to Time objects
    session_data[:timestamp] = Time.parse(session_data[:timestamp])
    session_data[:last_accessed] = Time.parse(session_data[:last_accessed]) if session_data[:last_accessed]
    
    @sessions[user_id] = session_data
    @access_order << user_id unless @access_order.include?(user_id)
    true
  end

  def cleanup_old_sessions(max_age_days = 7)
    cutoff_time = Time.now - (max_age_days * 24 * 60 * 60)
    
    old_sessions = @sessions.select do |user_id, session|
      session[:last_accessed] < cutoff_time
    end
    
    old_sessions.each { |user_id, _| remove_session(user_id) }
    old_sessions.length
  end

  def session_stats
    {
      total_sessions: @sessions.length,
      oldest_session: @sessions.values.min_by { |s| s[:timestamp] }&.dig(:timestamp),
      newest_session: @sessions.values.max_by { |s| s[:timestamp] }&.dig(:timestamp),
      most_accessed: @sessions.max_by { |_, s| s[:access_count] }&.first,
      memory_usage: calculate_memory_usage
    }
  end

  private

  def evict_session
    case @eviction_strategy
    when :lru
      evict_lru_session
    when :oldest
      evict_oldest_session
    when :least_accessed
      evict_least_accessed_session
    else
      evict_lru_session # Default to LRU
    end
  end

  def evict_lru_session
    # Remove the least recently used session (first in access order)
    return if @access_order.empty?
    
    lru_user_id = @access_order.first
    remove_session(lru_user_id)
  end

  def evict_oldest_session
    oldest_user_id = @sessions.min_by { |_, session| session[:timestamp] }&.first
    remove_session(oldest_user_id) if oldest_user_id
  end

  def evict_least_accessed_session
    least_accessed_user_id = @sessions.min_by { |_, session| session[:access_count] }&.first
    remove_session(least_accessed_user_id) if least_accessed_user_id
  end

  def calculate_memory_usage
    # Rough estimate of memory usage
    total_chars = 0
    @sessions.each_value do |session|
      total_chars += session[:context].to_s.length
    end
    "#{total_chars} characters (~#{(total_chars / 1024.0).round(2)} KB)"
  end
end