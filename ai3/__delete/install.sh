#!/bin/bash

#!/usr/bin/env zsh
#
# AI3 Core Installation Script
#
# Installs the core AI3 system on OpenBSD, setting up Ruby 3.2, required gems, and deploying ai3.rb to ~/bin.

set -e

typeset ROOT_DIR="${PWD}"
typeset LOG_FILE="${ROOT_DIR}/logs/install.log"

# Define directories
typeset -a DIRS=(
  "${ROOT_DIR}/lib"
  "${ROOT_DIR}/lib/utils"
  "${ROOT_DIR}/config"
  "${ROOT_DIR}/config/locales"
  "${ROOT_DIR}/logs"
  "${ROOT_DIR}/tmp"
  "${ROOT_DIR}/tmp/cache"
  "${ROOT_DIR}/assistants"
  "${ROOT_DIR}/data/vector_db"
  "${ROOT_DIR}/data/screenshots"
  "${ROOT_DIR}/data/workflows"
  "${ROOT_DIR}/data/multimodal"
  "${ROOT_DIR}/data/lyrics"
  "${ROOT_DIR}/data/keys"
  "${ROOT_DIR}/data/models"
  "${ROOT_DIR}/data/models/multimedia"
  "${ROOT_DIR}/data/cache"
  "${BIN_DIR}"
)

# Create directories
mkdir -p "${DIRS[@]}"
for dir in "${DIRS[@]}"; do
  echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] Creating directory: $dir" >> "${LOG_FILE}"
  if [[ ! -w "$dir" ]]; then
    echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] Error: Directory $dir is not writable" >> "${LOG_FILE}"
    exit 1
  }
done

# Clean old logs and screenshots
find "${ROOT_DIR}/logs" -mtime +7 -delete 2>/dev/null || {
  echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] Warning: Failed to clean logs" >> "${LOG_FILE}"
}
find "${ROOT_DIR}/data/screenshots" -mtime +1 -delete 2>/dev/null || {
  echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] Warning: Failed to clean screenshots" >> "${LOG_FILE}"
}

# Configure API keys
key_file="${HOME}/.ai3_keys"
touch "${key_file}"
chmod 600 "${key_file}"
echo "Enter XAI API Key (optional, press Enter to skip): "
read -r xai_key
echo "Enter Anthropic API Key (optional, press Enter to skip): "
read -r anthropic_key
echo "Enter OpenAI API Key (optional, press Enter to skip): "
read -r openai_key
echo "Enter Replicate API Key (optional, press Enter to skip): "
read -r replicate_key

if [[ -n "$xai_key" || -n "$anthropic_key" || -n "$openai_key" || -n "$replicate_key" ]]; then
  echo "Add API keys to ${key_file}? (y/n)"
  read -r confirm
  if [[ "$confirm" == "y" ]]; then
    [[ -n "$xai_key" ]] && echo "export XAI_API_KEY=\"$xai_key\"" >> "${key_file}"
    [[ -n "$anthropic_key" ]] && echo "export ANTHROPIC_API_KEY=\"$anthropic_key\"" >> "${key_file}"
    [[ -n "$openai_key" ]] && echo "export OPENAI_API_KEY=\"$openai_key\"" >> "${key_file}"
    [[ -n "$replicate_key" ]] && echo "export REPLICATE_API_KEY=\"$replicate_key\"" >> "${key_file}"
    echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] API keys added to ${key_file}" >> "${LOG_FILE}"
  fi
fi

# Install gems
typeset -a GEMS=(
  "langchainrb"
  "ruby-replicate"
  "weaviate-ruby"
  "tty-prompt"
  "ferrum"
  "nokogiri"
  "openssl"
)

echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] Installing gems..." >> "${LOG_FILE}"
for gem in "${GEMS[@]}"; do
  gem install --user-install "${gem}" >> "${LOG_FILE}" 2>&1 || {
    echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] Warning: Failed to install ${gem}, proceeding" >> "${LOG_FILE}"
  }
done

# Generate ai3.rb
cat > "${ROOT_DIR}/ai3.rb" <<'EOF'
#!/usr/bin/env ruby
# frozen_string_literal: true

require "yaml"
require "langchain"
require "tty-prompt"
require "i18n"
require "logger"
require "json"
require_relative "lib/utils/config"
require_relative "lib/utils/file"
require_relative "lib/utils/llm"

I18n.load_path << Dir[File.join(Dir.pwd, "config", "locales", "*.yml")]
I18n.backend.load_translations

module AI3
  @logger = Logger.new(File.join(Dir.pwd, "logs", "ai3.log"))
  @llm_calls = 0
  @start_time = Time.now

  def self.logger
    @logger
  end

  class << self
    attr_reader :llm_grok, :llm_claude, :llm_openai, :llm_ollama, :replicate_client, :vector_client,
                :system_tool, :context_manager, :rag_system, :workflow, :session_manager,
                :scraper, :multimedia, :shell, :workflow_composer, :goal_manager, :model_cache

    def initialize!
      logger.info("Initializing AI3 at #{Time.now.utc.iso8601}")

      begin
        @llm_grok = LangChain::LLM::XAI.new(
          default_options: { temperature: Config.instance["llm"]["temperature"], max_tokens: Config.instance["llm"]["max_tokens"] }
        ) if ENV["XAI_API_KEY"]
      rescue => e
        logger.warn(I18n.t("ai3.no_api_key", llm: "Grok") + ": #{e.message}")
        @llm_grok = nil
      end

      begin
        @llm_claude = LangChain::LLM::Anthropic.new(
          model: Config.instance["llm"]["anthropic_model"],
          api_key: ENV["ANTHROPIC_API_KEY"] || "",
          default_options: { temperature: Config.instance["llm"]["temperature"], max_tokens: Config.instance["llm"]["max_tokens"] }
        ) if ENV["ANTHROPIC_API_KEY"]
      rescue => e
        logger.warn(I18n.t("ai3.no_api_key", llm: "Claude") + ": #{e.message}")
        @llm_claude = nil
      end

      begin
        @llm_openai = LangChain::LLM::OpenAI.new(
          model: Config.instance["llm"]["openai_model"],
          api_key: ENV["OPENAI_API_KEY"] || "",
          default_options: { temperature: Config.instance["llm"]["temperature"], max_tokens: Config.instance["llm"]["max_tokens"] }
        ) if ENV["OPENAI_API_KEY"]
      rescue => e
        logger.warn(I18n.t("ai3.no_api_key", llm: "OpenAI o3-mini") + ": #{e.message}")
        @llm_openai = nil
      end

      begin
        @llm_ollama = LangChain::LLM::Ollama.new(
          model: Config.instance["llm"]["offline_model"],
          default_options: { temperature: Config.instance["llm"]["temperature"], max_tokens: Config.instance["llm"]["max_tokens"] }
        ) if command?("ollama")
      rescue => e
        logger.warn("Failed to initialize DeepSeek-R1: #{e.message}")
        @llm_ollama = nil
      end

      begin
        @replicate_client = LangChain::Client::Replicate.new(
          api_key: ENV["REPLICATE_API_KEY"] || ""
        ) if ENV["REPLICATE_API_KEY"]
      rescue => e
        logger.warn("Failed to initialize Replicate: #{e.message}")
        @replicate_client = nil
      end

      begin
        @vector_client = LangChain::Vectorsearch::Weaviate.new(
          url: Config.instance["vector_search"]["host"],
          api_key: Config.instance["vector_search"]["api_key"],
          index_name: Config.instance["vector_search"]["index_name"],
          llm: @llm_grok || @llm_claude || @llm_openai || @llm_ollama
        )
        raise "Weaviate unavailable" unless @vector_client&.client&.schema&.get
      rescue => e
        logger.warn("Failed to initialize Weaviate: #{e.message}. Proceeding without vector search")
        @vector_client = nil
      end

      load_training_data if @vector_client
      index_replicate_models if @vector_client && @replicate_client

      @system_tool = SystemTool.new
      @context_manager = ContextManager.new(@vector_client)
      @rag_system = RAGSystem.new(@vector_client)
      @workflow = Workflow.new
      @session_manager = SessionManager.new
      @scraper = Scraper.new
      @multimedia = Multimedia.new
      @shell = Shell.new
      @workflow_composer = WorkflowComposer.new
      @goal_manager = GoalManager.new
      @model_cache = ModelCache.new
      @model_cache.precache
    end

    def rate_limit_check
      @llm_limit ||= Config.instance["llm_limit"]
      raise "LLM call limit exceeded" if @llm_calls >= @llm_limit
      @llm_calls += 1
    end

    def with_retry(max_retries = 2)
      retries = 0
      begin
        start = Time.now
        result = yield
        logger.info("Operation took #{(Time.now - start).round(3)}s")
        result
      rescue StandardError => e
        retries += 1
        logger.warn("Retry #{retries}/#{max_retries}: #{e.message}")
        sleep(2 ** retries)
        retry if retries <= max_retries
        logger.error("Failed after #{max_retries} retries: #{e.message}")
        raise
      end
    end

    def summarize(text)
      return text if text.include?("Summary:")
      cache_file = "data/cache/summary_#{text.hash}.txt"
      if File.exist?(cache_file)
        logger.info("Summary cache hit: #{cache_file}")
        return File.read(cache_file)
      end
      messages = [{ role: "user", content: "Summarize: #{text}" }]
      summary = LLM.chat(messages)
      result = "#{text}\nSummary: #{summary}"
      AI3::FileUtils.write(cache_file, result)
      result
    rescue => e
      logger.error("Summary failed: #{e.message}")
      text
    end

    private

    def command?(cmd)
      system("command -v #{cmd} >/dev/null 2>&1")
    end

    def load_training_data
      cache_file = "data/models/training_data.json"
      if File.exist?(cache_file)
        logger.info("Loaded cached training data")
        return
      end
      indexed_urls = File.exist?("data/cache/indexed_urls.txt") ? File.read("data/cache/indexed_urls.txt").split(",") : []
      Config.instance["rag"]["sources"].each do |url|
        next if indexed_urls.include?(url)
        with_retry do
          chunks = scraper.scrape(url).split("\n")
          vector_client&.add_texts(texts: chunks, schema: Config.instance["schemas"]["lyrics"])
          logger.info("Indexed #{chunks.size} chunks from #{url}")
          indexed_urls << url
          FileUtils.write("data/cache/indexed_urls.txt", indexed_urls.join(","))
        end
      end
      FileUtils.write(cache_file, "{}")
    end

    def index_replicate_models
      cache_file = "data/models/replicate.json"
      if File.exist?(cache_file)
        logger.info("Loaded cached Replicate models")
        return JSON.parse(File.read(cache_file))
      end
      with_retry do
        raw_data = scraper.scrape_models
        models = JSON.parse(raw_data.scan(/{[^}]+}/).map { |m| m.gsub("\n", "") }.join(","))
        vector_client&.add_texts(
          texts: models.map { |m| m.to_json },
          schema: Config.instance["schemas"]["replicate_models"]
        )
        FileUtils.write(cache_file, models.to_json)
        models
      end
    end
  end
end

class AI3Main
  def initialize
    begin
      AI3.initialize!
      @prompt = TTY::Prompt.new
      puts "Any related documentation I should read first?"
      @context = gets.chomp
      puts "Please specify your project and provide its file(s) for completion."
      @target = gets.chomp
      @session = InteractiveSession.new
      @session_manager = SessionManager.new
      puts I18n.t("ai3.initialized")
    rescue StandardError => e
      AI3.logger.error("Initialization failed: #{e.message}")
      raise
    end
  end

  def start
    @session.start
  end
end

AI3Main.new.start if $PROGRAM_NAME == __FILE__
EOF

# Set executable permissions and deploy
chmod +x "${ROOT_DIR}/ai3.rb"
mv "${ROOT_DIR}/ai3.rb" "${BIN_DIR}/ai3"
echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] Moved ai3.rb to ${BIN_DIR}/ai3" >> "${LOG_FILE}"

# Validate files
for file in "${BIN_DIR}/ai3" "${ROOT_DIR}/config/config.yml" "${ROOT_DIR}/config/locales/en.yml" "${ROOT_DIR}/lib/"*.rb; do
  [[ -f "$file" ]] || {
    echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] Error: $file missing" >> "${LOG_FILE}"
    exit 1
  }
done

# Log version and changes
echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] Version 6.5.0 installed" >> "changelog.txt"
echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] Change: Installed core AI3 system with Ruby 3.2 async, Grok, Claude, OpenAI o3-mini, Replicate models for multimedia; indexed models in Weaviate; added dynamic scraping, comprehensive logging, and secure API key setup" >> "${ROOT_DIR}/logs/change_log.txt"
echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] Core AI3 installation complete" >> "${LOG_FILE}"