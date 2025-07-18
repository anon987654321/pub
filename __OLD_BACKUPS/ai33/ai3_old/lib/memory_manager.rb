# frozen_string_literal: true

class MemoryManager
  def initialize
    @user_context = {}
    @vector_search = Langchain::VectorSearch.new(api_key: ENV.fetch('WEAVIATE_API_KEY', nil))
  end

  # Store long-term memory and context
  def store_context(user_id, context)
    @user_context[user_id] ||= []
    @user_context[user_id] << context
    @vector_search.store(id: user_id, document: context)
    puts "Stored long-term context for user #{user_id}: #{context}"
  end

  # Retrieve long-term memory
  def retrieve_context(user_id)
    @user_context[user_id] || []
  end

  # Retrieve similar context using vector search for improved recall
  def retrieve_similar_context(query)
    similar_context = @vector_search.query(query: query)
    puts "Retrieved similar context: #{similar_context}"
    similar_context
  end

  # Clear outdated context automatically
  def clear_outdated_context(user_id)
    return unless @user_context[user_id]

    puts "Clearing outdated context for user #{user_id}..."
    @user_context[user_id].shift until @user_context[user_id].join(' ').length <= 4096
  end
end
