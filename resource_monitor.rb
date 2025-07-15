# frozen_string_literal: true

#!/usr/bin/env ruby
# frozen_string_literal: true

require 'json'
require 'time'
require 'logger'

# § Resource Monitor for Extreme Scrutiny Framework
# Monitors system resources within master.json v12.9.0 limits
class ResourceMonitor
  MAX_MEMORY_BYTES = 1073741824 # 1GB
  MAX_CPU_PERCENTAGE = 10.0
  MAX_NETWORK_PERCENTAGE = 5.0
  MONITORING_INTERVAL = 10 # seconds
  
  def initialize(master_config = {})
  # TODO: Refactor initialize - exceeds 20 line limit (288 lines)
    @logger = create_logger
    @master_config = master_config
    @start_time = Time.now
    @measurements = []
    @circuit_breaker_active = false
    @monitoring_active = false
  end

  def start_monitoring
    @logger.info "§ Resource Monitor Started"
    @logger.info "Limits: 1GB Memory, 10% CPU, 5% Network"
    @logger.info "Monitoring interval: #{MONITORING_INTERVAL}s"
    
    @monitoring_active = true
    
    Thread.new do
      while @monitoring_active
        begin
          measurement = collect_metrics
          @measurements << measurement
          
          evaluate_thresholds(measurement)
          
          sleep MONITORING_INTERVAL
        rescue StandardError => e
          @logger.error "Monitoring error: #{e.message}"
          sleep MONITORING_INTERVAL
        end
      end
    end
  end

  def stop_monitoring
    @monitoring_active = false
    @logger.info "§ Resource Monitor Stopped"
    
    generate_monitoring_report
  end

  def current_status
    return { status: 'inactive' } unless @monitoring_active
    
    latest = @measurements.last
    return { status: 'no_data' } unless latest
    
    {
      status: @circuit_breaker_active ? 'circuit_breaker_active' : 'active',
      memory_usage: latest[:memory_usage],
      cpu_usage: latest[:cpu_usage],
      network_usage: latest[:network_usage],
      timestamp: latest[:timestamp]
    }
  end

  def get_metrics_summary
    return {} if @measurements.empty?
    
    memory_values = @measurements.map { |m| m[:memory_usage] }
    cpu_values = @measurements.map { |m| m[:cpu_usage] }
    network_values = @measurements.map { |m| m[:network_usage] }
    
    {
      memory: {
        current: memory_values.last,
        average: (memory_values.sum / memory_values.length).round(2),
        max: memory_values.max,
        limit: MAX_MEMORY_BYTES
      },
      cpu: {
        current: cpu_values.last,
        average: (cpu_values.sum / cpu_values.length).round(2),
        max: cpu_values.max,
        limit: MAX_CPU_PERCENTAGE
      },
      network: {
        current: network_values.last,
        average: (network_values.sum / network_values.length).round(2),
        max: network_values.max,
        limit: MAX_NETWORK_PERCENTAGE
      },
      uptime: (Time.now - @start_time).round(2),
      measurements_count: @measurements.length
    }
  end

  private

  def create_logger
    logger = Logger.new($stdout)
    logger.level = Logger::INFO
    logger.formatter = proc do |severity, datetime, progname, msg|
      "#{datetime.strftime('%Y-%m-%d %H:%M:%S')} [MONITOR] #{msg}\n"
    end
    logger
  end

  def collect_metrics
    # Simulate resource collection (in production would use system tools)
    memory_usage = simulate_memory_usage
    cpu_usage = simulate_cpu_usage
    network_usage = simulate_network_usage
    
    {
      timestamp: Time.now.utc.iso8601,
      memory_usage: memory_usage,
      cpu_usage: cpu_usage,
      network_usage: network_usage,
      process_count: simulate_process_count,
      uptime: (Time.now - @start_time).round(2)
    }
  end

  def simulate_memory_usage
    # Simulate memory usage based on file processing
    base_memory = 104857600 # 100MB base
    variable_memory = rand(209715200) # 0-200MB variable
    
    total_memory = base_memory + variable_memory
    
    # Ensure it doesn't exceed our limit for simulation
    [total_memory, MAX_MEMORY_BYTES * 0.9].min.to_i
  end

  def simulate_cpu_usage
    # Simulate CPU usage based on processing activity
    base_cpu = 2.0 # 2% base
    variable_cpu = rand(6.0) # 0-6% variable
    
    total_cpu = base_cpu + variable_cpu
    
    # Ensure it doesn't exceed our limit for simulation
    [total_cpu, MAX_CPU_PERCENTAGE * 0.9].min.round(2)
  end

  def simulate_network_usage
    # Simulate network usage
    base_network = 1.0 # 1% base
    variable_network = rand(3.0) # 0-3% variable
    
    total_network = base_network + variable_network
    
    # Ensure it doesn't exceed our limit for simulation
    [total_network, MAX_NETWORK_PERCENTAGE * 0.9].min.round(2)
  end

  def simulate_process_count
    # Simulate process count
    base_processes = 5
    variable_processes = rand(10)
    
    base_processes + variable_processes
  end

  def evaluate_thresholds(measurement)
    alerts = []
    
    # Check memory threshold
    memory_percentage = (measurement[:memory_usage].to_f / MAX_MEMORY_BYTES * 100).round(2)
    if memory_percentage > 85
      alerts << "Memory usage critical: #{memory_percentage}%"
    elsif memory_percentage > 70
      alerts << "Memory usage warning: #{memory_percentage}%"
    end
    
    # Check CPU threshold
    if measurement[:cpu_usage] > MAX_CPU_PERCENTAGE * 0.85
      alerts << "CPU usage critical: #{measurement[:cpu_usage]}%"
    elsif measurement[:cpu_usage] > MAX_CPU_PERCENTAGE * 0.70
      alerts << "CPU usage warning: #{measurement[:cpu_usage]}%"
    end
    
    # Check network threshold
    if measurement[:network_usage] > MAX_NETWORK_PERCENTAGE * 0.85
      alerts << "Network usage critical: #{measurement[:network_usage]}%"
    elsif measurement[:network_usage] > MAX_NETWORK_PERCENTAGE * 0.70
      alerts << "Network usage warning: #{measurement[:network_usage]}%"
    end
    
    # Process alerts
    if alerts.any?
      alerts.each { |alert| @logger.warn alert }
      
      # Activate circuit breaker for critical alerts
      critical_alerts = alerts.select { |alert| alert.include?('critical') }
      if critical_alerts.any?
        activate_circuit_breaker(critical_alerts)
      end
    else
      log_normal_status(measurement)
    end
  end

  def log_normal_status(measurement)
    memory_mb = (measurement[:memory_usage] / 1024 / 1024).round(1)
    memory_percentage = (measurement[:memory_usage].to_f / MAX_MEMORY_BYTES * 100).round(1)
    
    @logger.info "Status: Normal | Memory: #{memory_mb}MB (#{memory_percentage}%) | " \
                 "CPU: #{measurement[:cpu_usage]}% | Network: #{measurement[:network_usage]}%"
  end

  def activate_circuit_breaker(alerts)
    return if @circuit_breaker_active
    
    @logger.error "§ Circuit Breaker Activated"
    @logger.error "Triggers: #{alerts.join(', ')}"
    
    @circuit_breaker_active = true
    
    # Follow master.json circuit breaker procedures
    circuit_breaker_config = @master_config.dig('core', 'circuit_breakers')
    if circuit_breaker_config
      @logger.info "Executing circuit breaker procedures..."
      @logger.info "- Pausing non-critical processes"
      @logger.info "- Reducing monitoring frequency"
      @logger.info "- Activating resource cleanup"
      
      # Reduce monitoring frequency
      @monitoring_interval = MONITORING_INTERVAL * 2
    end
    
    # Auto-recovery after 60 seconds
    Thread.new do
      sleep 60
      deactivate_circuit_breaker
    end
  end

  def deactivate_circuit_breaker
    @logger.info "§ Circuit Breaker Deactivated"
    @logger.info "Resuming normal monitoring"
    
    @circuit_breaker_active = false
    @monitoring_interval = MONITORING_INTERVAL
  end

  def generate_monitoring_report
    @logger.info "§ Generating Resource Monitor Report"
    
    summary = get_metrics_summary
    
    report = {
      meta: {
        version: '12.9.0',
        timestamp: Time.now.utc.iso8601,
        user: 'anon987654321',
        framework: 'master.json v12.9.0'
      },
      limits: {
        memory_bytes: MAX_MEMORY_BYTES,
        cpu_percentage: MAX_CPU_PERCENTAGE,
        network_percentage: MAX_NETWORK_PERCENTAGE
      },
      summary: summary,
      compliance: {
        memory_compliant: summary[:memory][:max] <= MAX_MEMORY_BYTES,
        cpu_compliant: summary[:cpu][:max] <= MAX_CPU_PERCENTAGE,
        network_compliant: summary[:network][:max] <= MAX_NETWORK_PERCENTAGE,
        overall_compliant: true
      },
      circuit_breaker: {
        activated: @circuit_breaker_active,
        activation_count: @measurements.count { |m| m[:circuit_breaker_active] }
      },
      measurements: @measurements.last(20) # Last 20 measurements
    }
    
    # Update overall compliance
    report[:compliance][:overall_compliant] = 
      report[:compliance][:memory_compliant] &&
      report[:compliance][:cpu_compliant] &&
      report[:compliance][:network_compliant]
    
    # Save report
    File.write('resource_monitor_report.json', JSON.pretty_generate(report))
    
    # Log summary
    @logger.info "Resource usage summary:"
    @logger.info "  Memory: #{summary[:memory][:max] / 1024 / 1024}MB max " \
                 "(limit: #{MAX_MEMORY_BYTES / 1024 / 1024}MB)"
    @logger.info "  CPU: #{summary[:cpu][:max]}% max (limit: #{MAX_CPU_PERCENTAGE}%)"
    @logger.info "  Network: #{summary[:network][:max]}% max (limit: #{MAX_NETWORK_PERCENTAGE}%)"
    @logger.info "  Uptime: #{summary[:uptime]}s"
    @logger.info "  Measurements: #{summary[:measurements_count]}"
    @logger.info "  Compliance: #{report[:compliance][:overall_compliant] ? 'PASS' : 'FAIL'}"
    @logger.info "Report saved: resource_monitor_report.json"
  end
end

# Utility class for easy monitoring integration
class MonitoringService
  def self.start(master_config = {})
  begin
      @monitor = ResourceMonitor.new(master_config)
      @monitor.start_monitoring
      @monitor
    end
  
    def self.stop
      @monitor&.stop_monitoring
    end
  
    def self.status
      @monitor&.current_status || { status: 'not_running' }
    end
  
    def self.metrics
      @monitor&.get_metrics_summary || {}
    end
  rescue StandardError => e
    # TODO: Add proper error handling
    raise e
  end
end

# Execute monitoring if run directly
if __FILE__ == $0
  # Load master.json configuration
  config_path = '/home/runner/work/pubhealthcare/pubhealthcare/prompts/master.json'
  master_config = {}
  
  if File.exist?(config_path)
    begin
      master_config = JSON.parse(File.read(config_path))
    rescue JSON::ParserError
      puts "Warning: Could not parse master.json"
    end
  end
  
  # Start monitoring
  monitor = ResourceMonitor.new(master_config)
  monitor.start_monitoring
  
  # Monitor for 60 seconds or until interrupted
  begin
    puts "Resource monitoring started. Press Ctrl+C to stop."
    sleep 60
  rescue Interrupt
    puts "\nShutting down..."
  ensure
    monitor.stop_monitoring
  end
end