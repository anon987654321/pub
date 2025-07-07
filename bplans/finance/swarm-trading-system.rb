require "yaml"
require "binance"
require "news-api"
require "json"
require "openai"
require "logger"
require "thor"
require "fileutils"

# Dette prosjektet simulerer en hedgefonds-baserte "swarm" av autonome trading-roboter.
# Hver robot fungerer uavhengig, lagrer sin tilstand i en .bin-fil og henter dynamisk informasjon
# ved hjelp av RAG for å forbedre handelsbeslutninger.

# Baseklasse for roboter i swarmen
class TradingBot
  attr_reader :id, :config

  def initialize(id)
    @id = id
    load_configuration
    setup_logging
    load_state
  end

  def run
    loop do
      begin
        execute_cycle     # Hovedsyklus hvor roboter henter data, analyserer, og utfører handler
        save_state        # Lagre robotens tilstand etter hver syklus
        sleep(30)         # Pauser for å unngå overbelastning
      rescue => e
        handle_error(e)   # Logger eventuelle feil
      end
    end
  end

  private

  # Laster robotens konfigurasjon
  def load_configuration
    @config = YAML.load_file("config.yml")
  end

  # Setter opp loggføring
  def setup_logging
    @logger = Logger.new("logs/#{id}_log.txt")
    @logger.level = Logger::INFO
  end

  # Laster tilstanden til roboten fra en binær fil
  def load_state
    @state_file = ".ai3/#{id}.bin"
    if File.exist?(@state_file)
      @state = File.binread(@state_file)
      @logger.info("#{id} lastet tilstand fra fil")
    else
      @state = {}  # Oppretter en tom tilstand om filen ikke finnes
    end
  end

  # Lagre robotens tilstand
  def save_state
    File.open(@state_file, 'wb') { |f| f.write(Marshal.dump(@state)) }
    @logger.info("#{id} lagret tilstand")
  end

  # Placeholder-metode for å utføre robotens hovedoppgave
  def execute_cycle
    raise NotImplementedError, "Dette må implementeres av den spesifikke roboten"
  end

  # Håndterer feil ved å logge dem
  def handle_error(exception)
    @logger.error("Feil oppstod: #{exception.message}")
  end
end

# Robot som henter markedsdata fra Binance
class MarketDataBot < TradingBot
  def initialize(id)
    super(id)
    connect_to_binance
  end

  private

  def connect_to_binance
    @binance_client = Binance::Client::REST.new(api_key: @config["binance_api_key"], secret_key: @config["binance_api_secret"])
    @logger.info("#{id} tilkoblet Binance API")
  end

  # Utfører en syklus av datainnhenting
  def execute_cycle
    @logger.info("#{id} henter markedsdata")
    market_data = fetch_market_data
    @logger.info("Markedsdata: #{market_data}")
    @state[:market_data] = market_data
  end

  # Henter markedsdata fra Binance
  def fetch_market_data
    @binance_client.ticker_price(symbol: @config["trading_pair"])
  rescue StandardError => e
    @logger.error("Kunne ikke hente markedsdata: #{e.message}")
    nil
  end
end

# Robot som henter sentimentdata fra nyheter og analyserer med OpenAI
class SentimentAnalysisBot < TradingBot
  def initialize(id)
    super(id)
    connect_to_openai
  end

  private

  def connect_to_openai
    @openai_client = OpenAI::Client.new(api_key: @config["openai_api_key"])
    @logger.info("#{id} tilkoblet OpenAI API")
  end

  # Utfører en syklus av sentimentanalyse
  def execute_cycle
    @logger.info("#{id} henter nyhetsoverskrifter")
    headlines = fetch_latest_news
    sentiment_score = analyze_sentiment(headlines)
    @logger.info("Sentimentanalyse: #{sentiment_score}")
    @state[:sentiment_score] = sentiment_score
  end

  # Henter de siste nyhetene
  def fetch_latest_news
    news_client = News::Client.new(api_key: @config["news_api_key"])
    news_client.get_top_headlines(country: "us")
  rescue StandardError => e
    @logger.error("Kunne ikke hente nyheter: #{e.message}")
    []
  end

  # Analyserer sentimentet i nyhetene ved hjelp av OpenAI
  def analyze_sentiment(headlines)
    text = headlines.map { |article| article[:title] }.join(" ")
    response = @openai_client.completions(engine: "text-davinci-003", prompt: "Analyser sentimentet: #{text}")
    response["choices"].first["text"].strip.to_f
  rescue StandardError => e
    @logger.error("Sentimentanalyse feilet: #{e.message}")
    0.0
  end
end

# Robot som utfører handel basert på datainnhenting fra andre roboter
class TradingExecutionBot < TradingBot
  def initialize(id)
    super(id)
    connect_to_binance
  end

  private

  def connect_to_binance
    @binance_client = Binance::Client::REST.new(api_key: @config["binance_api_key"], secret_key: @config["binance_api_secret"])
    @logger.info("#{id} tilkoblet Binance API")
  end

  # Utfører handel basert på sanntidsdata
  def execute_cycle
    market_data = @state[:market_data]
    sentiment_score = @state[:sentiment_score]

    if market_data && sentiment_score
      signal = predict_trading_signal(market_data, sentiment_score)
      execute_trade(signal)
    else
      @logger.warn("#{id} mangler nødvendig data for handel")
    end
  end

  # Forutsier handelsbeslutning basert på markedsdata og sentimentanalyse
  def predict_trading_signal(market_data, sentiment_score)
    if sentiment_score > 0.5 && market_data["price"].to_f > 50000
      "BUY"
    elsif sentiment_score < -0.5
      "SELL"
    else
      "HOLD"
    end
  end

  # Utfører handelen basert på signalet
  def execute_trade(signal)
    case signal
    when "BUY"
      @binance_client.create_order(symbol: @config["trading_pair"], side: "BUY", type: "MARKET", quantity: 0.001)
      log_trade("KJØP")
    when "SELL"
      @binance_client.create_order(symbol: @config["trading_pair"], side: "SELL", type: "MARKET", quantity: 0.001)
      log_trade("SELG")
    else
      log_trade("HOLD")
    end
  end

  # Logger handelsbeslutningen
  def log_trade(action)
    @logger.info("#{id} utførte handel: #{action}")
  end
end

# Kommando-linjegrensesnitt for å kjøre roboter i swarmen
class TradingCLI < Thor
  desc "run", "Kjør alle roboter i swarmen"
  def run
    bots = [
      MarketDataBot.new("bot_00001"),
      SentimentAnalysisBot.new("bot_00002"),
      TradingExecutionBot.new("bot_00003")
    ]
    threads = bots.map { |bot| Thread.new { bot.run } }
    threads.each(&:join)
  end

  desc "configure", "Sett opp konfigurasjon"
  def configure
    puts 'Angi Binance API-nøkkel:'
    binance_api_key = STDIN.gets.chomp
    puts 'Angi Binance API-hemmelighet:'
    binance_api_secret = STDIN.gets.chomp
    puts 'Angi News API-nøkkel:'
    news_api_key = STDIN.gets.chomp
    puts 'Angi OpenAI API-nøkkel:'
    openai_api_key = STDIN.gets.chomp

    config = {
      'binance_api_key' => binance_api_key,
      'binance_api_secret' => binance_api_secret,
      'news_api_key' => news_api_key,
      'openai_api_key' => openai_api_key,
      'trading_pair' => 'BTCUSDT'  # Standard handelspar
    }

    File.open('config.yml', 'w') { |file| file.write(config.to_yaml) }
    puts 'Konfigurasjon lagret.'
  end
end
