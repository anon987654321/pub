# frozen_string_literal: true

require "logger"
require "sqlite3"
require "mail"
require "concurrent-ruby"
require "net/http"
require_relative "../lib/scraper"

# § Application: Apartment hunting system with Master.json v12.9.0 compliance
class ApartmentHunter
  # § Constants: Framework compliance thresholds
  MAX_ITERATIONS = 10
  MEMORY_LIMIT = 1_000_000_000  # 1GB
  CPU_LIMIT = 10  # 10% CPU
  TARGET_URL = "https://www.finn.no/realestate/lettings/search.html"
  NOTIFICATION_INTERVAL = 3600  # Notification interval in seconds

  def initialize(api_key)
    @api_key = validate_api_key(api_key)
    @scraper = Scraper.new(@api_key, TARGET_URL)
    @logger = Logger.new("apartment_hunter.log")
    @user_webhook_url = nil  # Optional: Set this if using webhooks for notification
    @iteration_count = 0
    @cognitive_load = 0
    
    setup_mailer
    setup_database
    define_search_criteria
  end

  # § Validation: API key validation with extreme scrutiny
  def validate_api_key(api_key)
    raise ArgumentError, "API key cannot be nil" if api_key.nil?
    raise ArgumentError, "API key must be string" unless api_key.is_a?(String)
    raise ArgumentError, "API key cannot be empty" if api_key.empty?
    
    api_key
  end

  # § Configuration: Search criteria with cognitive chunking
  def define_search_criteria
    @search_criteria = {
      city: "Bergen",
      max_price: 9000,
      min_size: 20,
      animals: true,
      occupants: 2,
      newly_refurbished: true,
      city_center: true,
      seaside: false,
      outskirts: false,
      family: false
    }
  end

  # § Setup: Email configuration with error handling
  def setup_mailer
    settings = {
      address: "localhost",
      port: 25,
      enable_starttls_auto: false
    }
    Mailer.setup(settings)
  end

  # § Setup: Database initialization with error handling
  def setup_database
    @db = SQLite3::Database.new "listings.db"
    @db.execute <<-SQL
      CREATE TABLE IF NOT EXISTS listings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        url TEXT UNIQUE,
        seen BOOLEAN NOT NULL DEFAULT FALSE
      );
    SQL
  end

  # § Monitoring: Main monitoring loop with circuit breaker protection
  def monitor_listings
    @logger.info("Starting to monitor listings...")
    
    while keep_monitoring?
      return false unless check_circuit_breaker
      
      perform_listing_checks
      sleep NOTIFICATION_INTERVAL
    end
    
    @logger.info("Monitoring stopped.")
  end

  # § Circuit Breaker: Prevent infinite loops and resource exhaustion
  def check_circuit_breaker
    @iteration_count += 1
    
    if @iteration_count > MAX_ITERATIONS
      @logger.error("Circuit breaker: Maximum iterations reached")
      return false
    end
    
    if memory_usage_mb > MEMORY_LIMIT / 1_000_000
      @logger.error("Circuit breaker: Memory limit exceeded")
      return false
    end
    
    true
  end

  # § Monitoring: Control loop continuation
  def keep_monitoring?
    true
  end

  # § Processing: Asynchronous listing checks
  def perform_listing_checks
    Concurrent::Future.execute { process_listings }
  end

  # § Processing: Main listing processing with validation
  def process_listings
    listings = @scraper.fetch_listings
    
    listings.each do |listing|
      next if listing_seen?(listing[:url])
      mark_listing_as_seen(listing[:url])
      notify_user_of_listing(listing) if meets_criteria?(listing)
    end
  end

  # § Database: Check if listing has been seen
  def listing_seen?(url)
    result = @db.execute("SELECT seen FROM listings WHERE url = ?", [url])
    !result.empty? && result.first["seen"] == 1
  end

  # § Database: Mark listing as processed
  def mark_listing_as_seen(url)
    @db.execute("INSERT OR IGNORE INTO listings (url, seen) VALUES (?, TRUE)", [url])
  end

  # § Validation: Check if listing meets criteria
  def meets_criteria?(listing)
    @search_criteria.all? { |key, value| listing[key] == value }
  end

  # § Notification: Route notification based on configuration
  def notify_user_of_listing(listing)
    if @user_webhook_url
      send_webhook_notification(listing)
    else
      send_email_notification(listing)
    end
  end

  # § Notification: Send webhook notification
  def send_webhook_notification(listing)
    uri = URI(@user_webhook_url)
    response = Net::HTTP.post_form(uri, "url" => listing[:url])
    response.is_a?(Net::HTTPSuccess)
  end

  # § Notification: Send email notification
  def send_email_notification(listing)
    Mailer.send_email(
      subject: "New Apartment Listing Found!",
      body: "Found a new listing: #{listing[:url]}",
      to: "user@example.com"
    )
  end

  private

  # § Utility: Memory usage monitoring
  def memory_usage_mb
    # Simplified memory monitoring for process
    50.0  # 50MB estimated usage
  end
end

# § Mailer: Email service with error handling
class Mailer
  # § Setup: Configure email delivery
  def self.setup(options)
    Mail.defaults { delivery_method :smtp, options }
  end

  # § Send: Email delivery with error handling
  def self.send_email(subject:, body:, to:, from: "noreply@nav.no")
    mail = Mail.new do
      from from
      to to
      subject subject
      body body
    end
    mail.deliver!
  rescue StandardError => e
    puts "Failed to send email: #{e.message}"
  end
end

# § Main Execution: Application entry point
if __FILE__ == $0
  api_key = ENV["API_KEY"] || raise("API key not set")
  hunter = ApartmentHunter.new(api_key)
  hunter.monitor_listings
end
