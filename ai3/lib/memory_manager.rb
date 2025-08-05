# encoding: utf-8
# Memory management for session data with long-term context + vector search

class MemoryManager
  def initialize
    @memory = {}
    @user_context = {}
    
    # Initialize with fallback if Langchain not available
    begin
      require 'langchain'
      @vector_search = Langchain::VectorSearch.new(api_key: ENV.fetch('WEAVIATE_API_KEY', nil))
    rescue LoadError, StandardError
      @vector_search = nil
      puts "Warning: Vector search not available, using basic memory only"
    end
  end

  # Basic memory operations (existing interface)
  def store(user_id, key, value)
    @memory[user_id] ||= {}
    @memory[user_id][key] = value
  end

  def retrieve(user_id, key)
    @memory[user_id] ||= {}
    @memory[user_id][key]
  end

  def clear(user_id)
    @memory[user_id] = {}
  end

  def get_context(user_id)
    @memory[user_id] || {}
  end

  # Enhanced long-term memory operations (from backup)
  def store_context(user_id, context)
    @user_context[user_id] ||= []
    @user_context[user_id] << context
    
    if @vector_search
      @vector_search.store(id: user_id, document: context)
    end
    
    puts "Stored long-term context for user #{user_id}: #{context}"
  end

  def retrieve_context(user_id)
    @user_context[user_id] || []
  end

  def retrieve_similar_context(query)
    return [] unless @vector_search
    
    similar_context = @vector_search.query(query: query)
    puts "Retrieved similar context: #{similar_context}"
    similar_context
  rescue StandardError => e
    puts "Error retrieving similar context: #{e.message}"
    []
  end

  def clear_outdated_context(user_id)
    return unless @user_context[user_id]

    puts "Clearing outdated context for user #{user_id}..."
    @user_context[user_id].shift until @user_context[user_id].join(' ').length <= 4096
  end
end
