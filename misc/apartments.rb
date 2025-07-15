# frozen_string_literal: true

require "logger"
require "sqlite3"
require "mail"
require "concurrent-ruby"
require "net/http"
require_relative "../lib/scraper"

# § Core Apartment Hunting Framework
# Implements v12.9.0 extreme scrutiny framework with cognitive orchestration
class ApartmentHunter
  # § Constants: Resource Limits and Thresholds
  TARGET_URL = "https://www.finn.no/realestate/lettings/search.html"
  NOTIFICATION_INTERVAL = 3600  # Notification interval: 1 hour (3600s)
  MAX_ITERATIONS = 10  # Circuit breaker: prevent infinite loops
  MEMORY_LIMIT = 100_000_000  # 100MB memory limit
  CPU_THRESHOLD = 0.1  # 10% CPU limit

  # § Initialize: Setup with circuit breaker protection
  def initialize(api_key)
    validate_api_key(api_key)
    @api_key = api_key
    @iteration_count = 0
    @start_time = Time.now
    
    initialize_core_components
    setup_circuit_breakers
    setup_monitoring
  end

  # § Validation: API key extreme scrutiny
  def validate_api_key(api_key)
    raise ArgumentError, "API key cannot be nil" if api_key.nil?
    raise ArgumentError, "API key cannot be empty" if api_key.empty?
    raise ArgumentError, "API key must be string" unless api_key.is_a?(String)
    raise ArgumentError, "API key too short" if api_key.length < 8
  end

  # § Initialize: Core components setup
  def initialize_core_components
    @scraper = Scraper.new(@api_key, TARGET_URL)
    @logger = Logger.new("apartment_hunter.log")
    @user_webhook_url = nil
    
    setup_mailer
    setup_database
    define_search_criteria
  end

  # § Circuit Breaker: Resource monitoring
  def setup_circuit_breakers
    @circuit_breaker = {
      max_iterations: MAX_ITERATIONS,
      memory_limit: MEMORY_LIMIT,
      cpu_threshold: CPU_THRESHOLD
    }
  end

  # § Monitoring: Resource usage tracking
  def setup_monitoring
    @performance_metrics = {
      start_time: @start_time,
      total_iterations: 0,
      memory_usage: 0,
      cpu_usage: 0.0
    }
  end

  # § Configuration: Search criteria with validation
  def define_search_criteria
    @search_criteria = {
      city: validate_city("Bergen"),
      max_price: validate_price(9000),
      min_size: validate_size(20),
      animals: validate_boolean(true),
      occupants: validate_occupants(2),
      newly_refurbished: validate_boolean(true),
      city_center: validate_boolean(true),
      seaside: validate_boolean(false),
      outskirts: validate_boolean(false),
      family: validate_boolean(false)
    }
  end

  # § Validation: City name must be non-empty string
  def validate_city(city)
    raise ArgumentError, "City must be string" unless city.is_a?(String)
    raise ArgumentError, "City cannot be empty" if city.empty?
    city
  end

  # § Validation: Price must be positive integer
  def validate_price(price)
    raise ArgumentError, "Price must be integer" unless price.is_a?(Integer)
    raise ArgumentError, "Price must be positive" if price <= 0
    price
  end

  # § Validation: Size must be positive integer
  def validate_size(size)
    raise ArgumentError, "Size must be integer" unless size.is_a?(Integer)
    raise ArgumentError, "Size must be positive" if size <= 0
    size
  end

  # § Validation: Boolean values only
  def validate_boolean(value)
    raise ArgumentError, "Must be boolean" unless [true, false].include?(value)
    value
  end

  # § Validation: Occupants must be positive integer
  def validate_occupants(occupants)
    raise ArgumentError, "Occupants must be integer" unless occupants.is_a?(Integer)
    raise ArgumentError, "Occupants must be positive" if occupants <= 0
    occupants
  end

  # § Email: Mailer configuration with validation
  def setup_mailer
    settings = validate_mailer_settings({
      address: "localhost",
      port: 25,
      enable_starttls_auto: false
    })
    Mailer.setup(settings)
  end

  # § Validation: Mailer settings extreme scrutiny
  def validate_mailer_settings(settings)
    raise ArgumentError, "Settings must be hash" unless settings.is_a?(Hash)
    raise ArgumentError, "Address required" unless settings[:address]
    raise ArgumentError, "Port required" unless settings[:port]
    raise ArgumentError, "Port must be integer" unless settings[:port].is_a?(Integer)
    raise ArgumentError, "Port must be positive" if settings[:port] <= 0
    settings
  end

  # § Database: SQLite setup with error handling
  def setup_database
    @db = SQLite3::Database.new("listings.db")
    create_listings_table
  rescue SQLite3::Exception => e
    @logger.error("Database setup failed: #{e.message}")
    raise
  end

  # § Database: Table creation with validation
  def create_listings_table
    @db.execute <<-SQL
      CREATE TABLE IF NOT EXISTS listings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        url TEXT UNIQUE NOT NULL,
        seen BOOLEAN NOT NULL DEFAULT FALSE,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
      );
    SQL
  end

  # § Monitoring: Main loop with circuit breaker
  def monitor_listings
    @logger.info("Starting apartment monitoring with circuit breaker protection")
    
    while should_continue_monitoring?
      break unless check_circuit_breaker
      
      perform_monitoring_iteration
      update_performance_metrics
      
      sleep(NOTIFICATION_INTERVAL)
    end
    
    @logger.info("Monitoring stopped gracefully")
  end

  # § Circuit Breaker: Continuation logic
  def should_continue_monitoring?
    keep_monitoring? && @iteration_count < MAX_ITERATIONS
  end

  # § Circuit Breaker: Resource limit checks
  def check_circuit_breaker
    @iteration_count += 1
    
    if @iteration_count >= MAX_ITERATIONS
      @logger.error("Circuit breaker: Maximum iterations reached")
      return false
    end
    
    current_memory = get_memory_usage
    if current_memory > MEMORY_LIMIT
      @logger.error("Circuit breaker: Memory limit exceeded")
      return false
    end
    
    true
  end

  # § Performance: Memory usage calculation
  def get_memory_usage
    GC.stat[:heap_allocated_in_bytes]
  rescue StandardError
    0
  end

  # § Performance: Metrics updating
  def update_performance_metrics
    @performance_metrics[:total_iterations] = @iteration_count
    @performance_metrics[:memory_usage] = get_memory_usage
    @performance_metrics[:cpu_usage] = get_cpu_usage
  end

  # § Performance: CPU usage estimation
  def get_cpu_usage
    # Simplified CPU usage tracking
    (Time.now - @start_time) / @iteration_count rescue 0.0
  end

  # § Monitoring: Legacy compatibility
  def keep_monitoring?
    true
  end

  # § Processing: Single iteration with error handling
  def perform_monitoring_iteration
    perform_listing_checks
  rescue StandardError => e
    @logger.error("Monitoring iteration failed: #{e.message}")
    handle_monitoring_error(e)
  end

  # § Error Handling: Monitoring error recovery
  def handle_monitoring_error(error)
    case error
    when Net::TimeoutError
      @logger.warn("Network timeout, will retry next iteration")
    when SQLite3::Exception
      @logger.error("Database error, attempting recovery")
      setup_database
    else
      @logger.error("Unknown error: #{error.class}")
    end
  end

  # § Concurrency: Async processing with timeout
  def perform_listing_checks
    future = Concurrent::Future.execute do
      process_listings
    end
    
    future.value(30)  # 30 second timeout
  rescue Concurrent::TimeoutError
    @logger.error("Listing check timeout after 30 seconds")
    false
  end

  # § Processing: Listing processing with validation
  def process_listings
    listings = fetch_listings_safely
    return unless listings
    
    process_individual_listings(listings)
  end

  # § Data: Safe listing fetching
  def fetch_listings_safely
    @scraper.fetch_listings
  rescue StandardError => e
    @logger.error("Failed to fetch listings: #{e.message}")
    nil
  end

  # § Processing: Individual listing processing
  def process_individual_listings(listings)
    listings.each do |listing|
      next unless validate_listing_structure(listing)
      next if listing_already_seen?(listing[:url])
      
      process_new_listing(listing)
    end
  end

  # § Validation: Listing structure validation
  def validate_listing_structure(listing)
    return false unless listing.is_a?(Hash)
    return false unless listing[:url]
    return false unless listing[:url].is_a?(String)
    return false if listing[:url].empty?
    true
  end

  # § Processing: New listing workflow
  def process_new_listing(listing)
    mark_listing_as_seen(listing[:url])
    
    if meets_search_criteria?(listing)
      notify_user_of_listing(listing)
      @logger.info("New matching listing found: #{listing[:url]}")
    end
  end

  # § Database: Listing existence check
  def listing_already_seen?(url)
    listing_seen?(url)
  end

  # § Database: Listing seen check with error handling
  def listing_seen?(url)
    result = @db.execute("SELECT seen FROM listings WHERE url = ?", [url])
    !result.empty? && result.first["seen"] == 1
  rescue SQLite3::Exception => e
    @logger.error("Database error checking listing: #{e.message}")
    false
  end

  # § Database: Mark listing as processed
  def mark_listing_as_seen(url)
    @db.execute("INSERT OR IGNORE INTO listings (url, seen) VALUES (?, TRUE)", [url])
  rescue SQLite3::Exception => e
    @logger.error("Database error marking listing: #{e.message}")
  end

  # § Criteria: Search criteria matching
  def meets_search_criteria?(listing)
    return false unless validate_listing_structure(listing)
    
    @search_criteria.all? do |key, expected_value|
      listing_value = listing[key]
      matches_criterion?(listing_value, expected_value)
    end
  end

  # § Criteria: Individual criterion matching
  def matches_criterion?(listing_value, expected_value)
    case expected_value
    when TrueClass, FalseClass
      listing_value == expected_value
    when Integer
      listing_value.to_i <= expected_value if expected_value == @search_criteria[:max_price]
      listing_value.to_i >= expected_value if expected_value == @search_criteria[:min_size]
    when String
      listing_value.to_s.downcase == expected_value.downcase
    else
      listing_value == expected_value
    end
  end

  # § Notifications: User notification routing
  def notify_user_of_listing(listing)
    return unless validate_listing_structure(listing)
    
    if @user_webhook_url
      send_webhook_notification(listing)
    else
      send_email_notification(listing)
    end
  end

  # § Webhook: HTTP notification with timeout
  def send_webhook_notification(listing)
    uri = URI(@user_webhook_url)
    
    Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https") do |http|
      request = Net::HTTP::Post.new(uri)
      request.set_form_data("url" => listing[:url])
      
      response = http.request(request)
      response.is_a?(Net::HTTPSuccess)
    end
  rescue StandardError => e
    @logger.error("Webhook notification failed: #{e.message}")
    false
  end

  # § Email: Email notification with validation
  def send_email_notification(listing)
    Mailer.send_email(
      subject: "New Apartment Listing Found!",
      body: generate_email_body(listing),
      to: "user@example.com"
    )
  rescue StandardError => e
    @logger.error("Email notification failed: #{e.message}")
    false
  end

  # § Email: Email body generation
  def generate_email_body(listing)
    "Found a new listing: #{listing[:url]}\n\n" \
    "Details:\n" \
    "City: #{listing[:city]}\n" \
    "Price: #{listing[:max_price]}\n" \
    "Size: #{listing[:min_size]} sqm"
  end
end

# § Mailer: Email service with error handling
class Mailer
  # § Setup: SMTP configuration
  def self.setup(options)
    validate_smtp_options(options)
    Mail.defaults { delivery_method :smtp, options }
  end

  # § Validation: SMTP options validation
  def self.validate_smtp_options(options)
    raise ArgumentError, "Options must be hash" unless options.is_a?(Hash)
    raise ArgumentError, "Address required" unless options[:address]
    raise ArgumentError, "Port required" unless options[:port]
  end

  # § Email: Send email with validation
  def self.send_email(subject:, body:, to:, from: "noreply@nav.no")
    validate_email_params(subject, body, to, from)
    
    mail = Mail.new do
      from from
      to to
      subject subject
      body body
    end
    
    mail.deliver!
    true
  rescue StandardError => e
    puts "Failed to send email: #{e.message}"
    false
  end

  # § Validation: Email parameters validation
  def self.validate_email_params(subject, body, to, from)
    raise ArgumentError, "Subject cannot be empty" if subject.to_s.empty?
    raise ArgumentError, "Body cannot be empty" if body.to_s.empty?
    raise ArgumentError, "To address cannot be empty" if to.to_s.empty?
    raise ArgumentError, "From address cannot be empty" if from.to_s.empty?
  end
end

# § Main: Entry point with error handling
if __FILE__ == $0
  begin
    api_key = ENV["API_KEY"] || raise("API_KEY environment variable not set")
    hunter = ApartmentHunter.new(api_key)
    hunter.monitor_listings
  rescue StandardError => e
    puts "Application error: #{e.message}"
    exit 1
  end
end
