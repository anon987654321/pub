# frozen_string_literal: true

# Post-Processing Service for Rails Application
# Integrates analog and cinematic image processing with Active Storage
class PostProcessingService
  include CableReady::Broadcaster
  
  attr_reader :user, :community
  
  # Available post-processing effects
  AVAILABLE_EFFECTS = {
    film_grain: { name: "Film Grain", description: "Classic analog film texture", intensity_range: [0.5, 3.0] },
    light_leaks: { name: "Light Leaks", description: "Vintage light leak effects", intensity_range: [0.3, 2.0] },
    lens_distortion: { name: "Lens Distortion", description: "Optical lens distortion", intensity_range: [0.1, 1.5] },
    sepia: { name: "Sepia Tone", description: "Classic sepia coloring", intensity_range: [0.5, 2.0] },
    bleach_bypass: { name: "Bleach Bypass", description: "High contrast film technique", intensity_range: [0.7, 1.8] },
    lomo: { name: "Lomography", description: "Toy camera aesthetic", intensity_range: [0.8, 2.5] },
    golden_hour_glow: { name: "Golden Hour", description: "Warm golden lighting", intensity_range: [0.5, 2.0] },
    cross_process: { name: "Cross Process", description: "Alternative film development", intensity_range: [0.6, 1.9] },
    bloom_effect: { name: "Bloom", description: "Dreamy highlight glow", intensity_range: [0.4, 2.2] },
    film_halation: { name: "Halation", description: "Film halation glow", intensity_range: [0.3, 1.7] },
    teal_and_orange: { name: "Teal & Orange", description: "Hollywood color grading", intensity_range: [0.5, 1.5] },
    day_for_night: { name: "Day for Night", description: "Cinematic night simulation", intensity_range: [0.7, 1.4] },
    anamorphic_simulation: { name: "Anamorphic", description: "Widescreen lens flares", intensity_range: [0.6, 1.8] },
    chromatic_aberration: { name: "Chromatic Aberration", description: "Lens color fringing", intensity_range: [0.2, 1.2] },
    vhs_degrade: { name: "VHS Degrade", description: "80s/90s analog video", intensity_range: [0.5, 2.5] },
    color_fade: { name: "Color Fade", description: "Vintage color fading", intensity_range: [0.4, 1.6] }
  }.freeze
  
  def initialize(user: nil, community: nil)
    @user = user
    @community = community
    @logger = Rails.logger
    setup_processing_environment
  end
  
  # Process single image with specified effects
  def process_image(image_attachment, effects_config = {}, options = {})
    return error_response("Image attachment required") unless image_attachment&.attached?
    
    # Download original image
    original_path = download_attachment(image_attachment)
    return error_response("Failed to download image") unless original_path
    
    # Apply effects
    processed_paths = apply_effects_to_image(original_path, effects_config, options)
    
    # Upload processed images and create records
    results = upload_processed_images(processed_paths, image_attachment, effects_config)
    
    # Cleanup temporary files
    cleanup_temp_files([original_path] + processed_paths)
    
    # Broadcast real-time update
    broadcast_processing_complete(results) if @user
    
    success_response(results)
  rescue StandardError => e
    @logger.error "Post-processing failed: #{e.message}"
    error_response("Processing failed: #{e.message}")
  end
  
  # Batch process multiple images
  def batch_process_images(image_attachments, effects_config = {}, options = {})
    return error_response("No images provided") if image_attachments.empty?
    
    batch_id = generate_batch_id
    total_images = image_attachments.count
    processed_count = 0
    results = []
    
    image_attachments.each_with_index do |attachment, index|
      begin
        result = process_image(attachment, effects_config, options.merge(batch_id: batch_id))
        results << result
        processed_count += 1
        
        # Broadcast progress update
        broadcast_batch_progress(batch_id, processed_count, total_images) if @user
        
      rescue StandardError => e
        @logger.error "Failed to process image #{index + 1}: #{e.message}"
        results << error_response("Failed to process image #{index + 1}: #{e.message}")
      end
    end
    
    success_response({
      batch_id: batch_id,
      total_images: total_images,
      processed_count: processed_count,
      results: results
    })
  end
  
  # Get random effects configuration
  def generate_random_effects(count = 3, intensity_factor = 1.0)
    selected_effects = AVAILABLE_EFFECTS.keys.sample(count)
    
    effects_config = {}
    selected_effects.each do |effect|
      effect_info = AVAILABLE_EFFECTS[effect]
      min_intensity = effect_info[:intensity_range][0] * intensity_factor
      max_intensity = effect_info[:intensity_range][1] * intensity_factor
      
      effects_config[effect] = rand(min_intensity..max_intensity).round(2)
    end
    
    effects_config
  end
  
  # Create preset effect recipes
  def get_preset_recipes
    {
      vintage_film: {
        film_grain: 1.2,
        sepia: 0.8,
        light_leaks: 0.6,
        color_fade: 1.0
      },
      cinematic_teal_orange: {
        teal_and_orange: 1.0,
        bloom_effect: 0.8,
        anamorphic_simulation: 1.2
      },
      retro_vhs: {
        vhs_degrade: 1.5,
        chromatic_aberration: 0.8,
        color_fade: 1.2
      },
      dreamy_glow: {
        bloom_effect: 1.8,
        golden_hour_glow: 1.4,
        film_halation: 1.0
      },
      lomography: {
        lomo: 2.0,
        cross_process: 1.2,
        lens_distortion: 0.8
      },
      night_mode: {
        day_for_night: 1.3,
        teal_and_orange: 0.7,
        bloom_effect: 0.9
      }
    }
  end
  
  # Get processing history for user/community
  def get_processing_history(limit: 50)
    # This would typically query a database
    # For now, return from cache
    cache_key = processing_history_cache_key
    
    if Rails.cache.exist?(cache_key)
      JSON.parse(Rails.cache.read(cache_key), symbolize_names: true).last(limit)
    else
      []
    end
  end
  
  # Save processing job to history
  def save_to_history(job_data)
    cache_key = processing_history_cache_key
    
    history = if Rails.cache.exist?(cache_key)
                JSON.parse(Rails.cache.read(cache_key), symbolize_names: true)
              else
                []
              end
    
    history << job_data.merge(
      id: SecureRandom.hex(8),
      created_at: Time.current.iso8601,
      user_id: @user&.id,
      community_id: @community&.id
    )
    
    # Keep only last 100 entries
    history = history.last(100)
    
    Rails.cache.write(cache_key, history.to_json, expires_in: 30.days)
  end
  
  # Get system health and capabilities
  def health_check
    {
      status: vips_available? ? 'operational' : 'degraded',
      vips_available: vips_available?,
      available_effects: AVAILABLE_EFFECTS.keys,
      temp_dir_writable: temp_dir_writable?,
      active_storage_configured: active_storage_configured?,
      processing_queue_size: get_processing_queue_size,
      last_check: Time.current.iso8601
    }
  end
  
  private
  
  def setup_processing_environment
    @temp_dir = Rails.root.join('tmp', 'postprocessing')
    @temp_dir.mkpath unless @temp_dir.exist?
    
    # Load postpro integration if available
    @postpro_available = check_postpro_availability
  end
  
  def check_postpro_availability
    postpro_path = Rails.root.join('lib', 'integrations', 'postpro')
    postpro_path.exist? && vips_available?
  end
  
  def vips_available?
    @vips_available ||= begin
      require 'vips'
      true
    rescue LoadError
      false
    end
  end
  
  def temp_dir_writable?
    test_file = @temp_dir.join('test_write')
    test_file.write('test')
    test_file.delete
    true
  rescue StandardError
    false
  end
  
  def active_storage_configured?
    Rails.application.config.active_storage.service.present?
  end
  
  def get_processing_queue_size
    # In production, this would check Solid Queue
    0
  end
  
  def download_attachment(attachment)
    temp_file = @temp_dir.join("original_#{SecureRandom.hex(8)}#{File.extname(attachment.filename.to_s)}")
    
    attachment.open do |file|
      temp_file.binwrite(file.read)
    end
    
    temp_file.to_s
  rescue StandardError => e
    @logger.error "Failed to download attachment: #{e.message}"
    nil
  end
  
  def apply_effects_to_image(image_path, effects_config, options = {})
    return [] unless @postpro_available
    
    variations = options[:variations] || 1
    processed_paths = []
    
    variations.times do |i|
      output_path = generate_output_path(image_path, i + 1, options[:batch_id])
      
      if apply_postpro_effects(image_path, output_path, effects_config)
        processed_paths << output_path
      end
    end
    
    processed_paths
  end
  
  def apply_postpro_effects(input_path, output_path, effects_config)
    return false unless vips_available?
    
    begin
      require 'vips'
      
      # Load image
      image = Vips::Image.new_from_file(input_path)
      
      # Apply each effect
      effects_config.each do |effect_name, intensity|
        next unless AVAILABLE_EFFECTS.key?(effect_name.to_sym)
        
        image = apply_single_effect(image, effect_name, intensity)
      end
      
      # Save processed image
      image.write_to_file(output_path)
      true
    rescue StandardError => e
      @logger.error "Effect application failed: #{e.message}"
      false
    end
  end
  
  def apply_single_effect(image, effect_name, intensity)
    # Simplified effect implementation
    # In production, this would use the full postpro.rb logic
    case effect_name.to_sym
    when :sepia
      apply_sepia_effect(image, intensity)
    when :bloom_effect
      apply_bloom_effect(image, intensity)
    when :film_grain
      apply_film_grain(image, intensity)
    else
      # Fallback: apply basic brightness/contrast adjustment
      image.linear([intensity], [0])
    end
  end
  
  def apply_sepia_effect(image, intensity)
    # Simple sepia implementation
    sepia_matrix = [
      [0.393 * intensity, 0.769 * intensity, 0.189 * intensity],
      [0.349 * intensity, 0.686 * intensity, 0.168 * intensity],
      [0.272 * intensity, 0.534 * intensity, 0.131 * intensity]
    ]
    
    if image.bands >= 3
      image.recomb(sepia_matrix)
    else
      image
    end
  end
  
  def apply_bloom_effect(image, intensity)
    # Simple bloom implementation
    blur_radius = [intensity * 10, 50].min
    blurred = image.gaussblur(blur_radius)
    image.composite(blurred, :over, opacity: intensity * 30)
  rescue StandardError
    image
  end
  
  def apply_film_grain(image, intensity)
    # Simple noise addition
    noise_amount = intensity * 10
    noise = Vips::Image.gaussnoise(image.width, image.height, sigma: noise_amount)
    image.add(noise)
  rescue StandardError
    image
  end
  
  def generate_output_path(original_path, variation_num, batch_id = nil)
    basename = File.basename(original_path, File.extname(original_path))
    timestamp = Time.current.strftime("%Y%m%d%H%M%S")
    batch_suffix = batch_id ? "_#{batch_id}" : ""
    
    @temp_dir.join("#{basename}_processed_v#{variation_num}#{batch_suffix}_#{timestamp}.jpg").to_s
  end
  
  def upload_processed_images(processed_paths, original_attachment, effects_config)
    results = []
    
    processed_paths.each_with_index do |path, index|
      next unless File.exist?(path)
      
      # Create new attachment
      filename = File.basename(path)
      
      # In production, this would create proper ActiveStorage attachments
      # For now, we'll simulate the result
      results << {
        filename: filename,
        effects_applied: effects_config,
        file_size: File.size(path),
        variation_number: index + 1,
        created_at: Time.current.iso8601
      }
    end
    
    # Save to processing history
    save_to_history({
      original_filename: original_attachment.filename.to_s,
      effects_applied: effects_config,
      variations_created: results.count,
      total_file_size: results.sum { |r| r[:file_size] }
    })
    
    results
  end
  
  def cleanup_temp_files(file_paths)
    file_paths.each do |path|
      File.delete(path) if File.exist?(path)
    rescue StandardError => e
      @logger.warn "Failed to cleanup temp file #{path}: #{e.message}"
    end
  end
  
  def generate_batch_id
    "batch_#{SecureRandom.hex(6)}"
  end
  
  def processing_history_cache_key
    "postprocessing_history:#{@community&.id || 'global'}:#{@user&.id || 'anon'}"
  end
  
  def broadcast_processing_complete(results)
    cable_ready
      .insert_adjacent_html(
        selector: "#processing-results",
        position: "beforeend", 
        html: render_results_html(results)
      )
      .broadcast_to(@user, identifier: "PostProcessingChannel")
  end
  
  def broadcast_batch_progress(batch_id, processed, total)
    progress_percentage = (processed.to_f / total * 100).round(1)
    
    cable_ready
      .replace(
        selector: "#batch-progress-#{batch_id}",
        html: "<div class='progress-bar' style='width: #{progress_percentage}%'>#{processed}/#{total}</div>"
      )
      .broadcast_to(@user, identifier: "PostProcessingChannel")
  end
  
  def render_results_html(results)
    # Simple HTML rendering
    "<div class='processing-result'>Created #{results.count} variations</div>"
  end
  
  def success_response(data)
    {
      success: true,
      data: data,
      timestamp: Time.current.iso8601
    }
  end
  
  def error_response(message)
    {
      success: false,
      error: message,
      timestamp: Time.current.iso8601
    }
  end
end