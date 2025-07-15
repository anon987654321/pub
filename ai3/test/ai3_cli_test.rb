# frozen_string_literal: true

require "bundler/setup"
require "minitest/autorun"
require_relative "../ai3_cli"

# Comprehensive test suite for AI³ CLI tool
class AI3CLITest < Minitest::Test
  def setup
    # Clean up any existing test data
    cleanup_test_data
    
    # Create a test configuration
    @test_config = {
      "llm" => { "primary" => "xai", "fallback_enabled" => true },
      "cognitive" => { "max_working_memory" => 7 },
      "session" => { "max_sessions" => 5 },
      "rag" => { "enabled" => true, "vector_db_path" => "tmp/test_vector_store.db" },
      "scraper" => { "enabled" => true },
      "assistants" => { "default_assistant" => "general" }
    }
    
    # Mock CLI instance
    @cli = AI3CLI.allocate
    @cli.instance_variable_set(:@app_config, @test_config)
    @cli.instance_variable_set(:@pastel, Pastel.new)
    @cli.instance_variable_set(:@prompt, TTY::Prompt.new)
  end

  def teardown
    cleanup_test_data
  end

  def test_cli_initialization
    # Test that CLI can be initialized with configuration
    refute_nil @cli.app_config
    assert_equal "xai", @cli.app_config.dig("llm", "primary")
    assert_equal 7, @cli.app_config.dig("cognitive", "max_working_memory")
  end

  def test_configuration_loading
    # Test configuration loading from file
    cli = AI3CLI.allocate
    config = cli.send(:load_configuration, "config/config.yml")
    
    assert_instance_of Hash, config
    assert config.key?("llm")
    assert config.key?("cognitive")
    assert config.key?("session")
    assert config.key?("rag")
  end

  def test_input_validation
    # Test input validation for security
    cli = AI3CLI.allocate
    
    # Valid input should not raise error
    begin
      cli.send(:validate_input, "Hello, this is a normal message")
    rescue => e
      flunk "Valid input should not raise error: #{e.message}"
    end
    
    # Invalid input should raise error
    assert_raises(ArgumentError) do
      cli.send(:validate_input, "$(malicious command)")
    end
    
    assert_raises(ArgumentError) do
      cli.send(:validate_input, "`command substitution`")
    end
    
    assert_raises(ArgumentError) do
      cli.send(:validate_input, "<script>alert('xss')</script>")
    end
  end

  def test_url_validation
    cli = AI3CLI.allocate
    
    # Valid URLs should not raise error
    begin
      cli.send(:validate_url, "https://example.com")
      cli.send(:validate_url, "http://example.com/path")
    rescue => e
      flunk "Valid URLs should not raise error: #{e.message}"
    end
    
    # Invalid URLs should raise error
    assert_raises(ArgumentError) do
      cli.send(:validate_url, "javascript:alert('xss')")
    end
    
    assert_raises(ArgumentError) do
      cli.send(:validate_url, "ftp://example.com")
    end
    
    assert_raises(ArgumentError) do
      cli.send(:validate_url, "not-a-url")
    end
  end

  def test_environment_variable_substitution
    cli = AI3CLI.allocate
    
    # Set test environment variable
    ENV["TEST_VAR"] = "test_value"
    
    config = {
      "test_key" => "${TEST_VAR}",
      "nested" => {
        "test_nested" => "${TEST_VAR}"
      }
    }
    
    result = cli.send(:substitute_env_vars, config)
    
    assert_equal "test_value", result["test_key"]
    assert_equal "test_value", result["nested"]["test_nested"]
    
    # Clean up
    ENV.delete("TEST_VAR")
  end

  def test_directory_setup
    cli = AI3CLI.allocate
    
    # Remove test directories if they exist
    %w[data logs tmp config screenshots].each do |dir|
      FileUtils.rm_rf(dir) if Dir.exist?(dir)
    end
    
    # Test directory creation
    cli.send(:setup_directories)
    
    # Verify directories were created
    %w[data logs tmp config screenshots].each do |dir|
      assert Dir.exist?(dir), "Directory #{dir} should exist"
    end
  end

  def test_default_configuration
    cli = AI3CLI.allocate
    config = cli.send(:default_configuration)
    
    assert_instance_of Hash, config
    assert_equal "xai", config.dig("llm", "primary")
    assert_equal 7, config.dig("cognitive", "max_working_memory")
    assert config.dig("rag", "enabled")
  end

  def test_command_structure_cognitive_chunking
    # Test that command structure follows 7±2 cognitive chunking
    cli = AI3CLI.allocate
    
    # Get all available commands
    commands = AI3CLI.all_commands.keys
    
    # Should have reasonable number of top-level commands (7±2)
    assert commands.length <= 10, "Too many top-level commands for cognitive load management"
    assert commands.length >= 5, "Too few commands for comprehensive functionality"
    
    # Verify essential commands exist
    essential_commands = %w[chat rag scrape list status help version]
    essential_commands.each do |cmd|
      assert commands.include?(cmd), "Essential command #{cmd} missing"
    end
  end

  def test_help_system_accessibility
    # Test that help system follows accessibility guidelines
    cli = AI3CLI.allocate
    
    # Test help command exists
    assert AI3CLI.all_commands.key?("help")
    
    # Test long descriptions are present for complex commands
    chat_command = AI3CLI.all_commands["chat"]
    assert chat_command.long_description.length > 100, "Chat command should have detailed help"
    
    rag_command = AI3CLI.all_commands["rag"]
    assert rag_command.long_description.length > 100, "RAG command should have detailed help"
  end

  def test_error_handling
    # Test graceful error handling
    cli = AI3CLI.allocate
    cli.instance_variable_set(:@pastel, Pastel.new)
    
    # Should not crash on error
    error = StandardError.new("Test error")
    
    # Create temporary log directory
    FileUtils.mkdir_p("logs")
    
    begin
      cli.send(:handle_error, error)
    rescue => e
      flunk "Error handling should not crash: #{e.message}"
    end
    
    # Verify error was logged
    assert File.exist?("logs/errors.log"), "Error log should be created"
  end

  private

  def cleanup_test_data
    # Clean up any test databases and files
    test_files = %w[
      tmp/test_vector_store.db
      logs/errors.log
      data/sessions.db
    ]
    
    test_files.each do |file|
      File.delete(file) if File.exist?(file)
    end
    
    # Clean up test directories
    %w[tmp/test_data].each do |dir|
      FileUtils.rm_rf(dir) if Dir.exist?(dir)
    end
  end
end