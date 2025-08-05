# frozen_string_literal: true

require 'ferrum'
require 'nokogiri'
require 'fileutils'
require 'uri'
require 'digest'

# Universal Scraper with Ferrum for web content and screenshots
# Includes cognitive load awareness and depth-based analysis
class UniversalScraper
  attr_reader :browser, :config, :cognitive_monitor

  def initialize(config = {})
    @config = default_config.merge(config)
    @cognitive_monitor = nil
    @screenshot_dir = @config[:screenshot_dir]
    @max_depth = @config[:max_depth]
    @timeout = @config[:timeout]
    @user_agent = @config[:user_agent]

    # Ensure screenshot directory exists
    FileUtils.mkdir_p(@screenshot_dir)

    # Initialize browser with error handling
    initialize_browser
  end

  # Set cognitive monitor for load-aware processing
  def set_cognitive_monitor(monitor)
    @cognitive_monitor = monitor
  end

  # Main scraping method with cognitive awareness
  def scrape(url, options = {})
    # Check cognitive capacity
    if @cognitive_monitor&.cognitive_overload?
      puts '🧠 Cognitive overload detected, deferring scraping'
      return { error: 'Cognitive overload - scraping deferred' }
    end

    # Validate URL
    return { error: 'Invalid URL' } unless valid_url?(url)

    begin
      puts "🕷️ Scraping #{url}..."

      # Navigate to page
      @browser.go_to(url)
      wait_for_page_load

      # Take screenshot
      screenshot_path = take_screenshot(url)

      # Extract content
      content = extract_content

      # Analyze page structure
      analysis = analyze_page_structure

      # Extract links for depth-based scraping
      links = extract_links(url) if options[:extract_links]

      # Update cognitive load
      if @cognitive_monitor
        complexity = calculate_content_complexity(content)
        @cognitive_monitor.add_concept(url, complexity * 0.1)
      end

      result = {
        url: url,
        title: content[:title],
        content: content[:text],
        html: content[:html],
        screenshot: screenshot_path,
        analysis: analysis,
        links: links,
        timestamp: Time.now,
        success: true
      }

      puts "✅ Successfully scraped #{url}"
      result
    rescue StandardError => e
      puts "❌ Scraping failed for #{url}: #{e.message}"
      { url: url, error: e.message, success: false }
    end
  end

  # Scrape multiple URLs with cognitive load balancing
  def scrape_multiple(urls, options = {})
    results = []

    urls.each_with_index do |url, index|
      # Check cognitive state before each scrape
      if @cognitive_monitor&.cognitive_overload?
        puts "🧠 Cognitive overload detected, stopping batch scrape at #{index}/#{urls.size}"
        break
      end

      result = scrape(url, options)
      results << result

      # Brief pause between requests
      sleep(1) if options[:delay]

      # Progress update
      puts "📊 Progress: #{index + 1}/#{urls.size} URLs scraped"
    end

    results
  end

  # Deep scrape with configurable depth
  def deep_scrape(start_url, depth = nil, visited = Set.new)
    depth ||= @max_depth
    return [] if depth <= 0 || visited.include?(start_url)

    # Check cognitive capacity
    if @cognitive_monitor&.cognitive_overload?
      puts '🧠 Cognitive overload detected, stopping deep scrape'
      return []
    end

    visited.add(start_url)
    results = []

    # Scrape current page
    result = scrape(start_url, extract_links: true)
    results << result if result[:success]

    # Recursively scrape linked pages
    if result[:success] && result[:links]
      result[:links].take(5).each do |link| # Limit to 5 links per page
        next if visited.include?(link) || !same_domain?(start_url, link)

        deeper_results = deep_scrape(link, depth - 1, visited)
        results.concat(deeper_results)
      end
    end

    results
  end

  # Extract content from current page
  def extract_content
    title = @browser.evaluate('document.title') || ''

    # Extract main text content
    text_content = @browser.evaluate(<<~JS)
      // Remove script and style elements
      var scripts = document.querySelectorAll('script, style, nav, footer, aside');
      scripts.forEach(function(el) { el.remove(); });

      // Get main content areas
      var main = document.querySelector('main, article, .content, #content, .post, .article');
      if (main) {
        return main.innerText;
      }

      // Fallback to body content
      return document.body.innerText;
    JS

    # Get full HTML
    html = @browser.evaluate('document.documentElement.outerHTML')

    {
      title: title.strip,
      text: clean_text(text_content || ''),
      html: html
    }
  end

  # Take screenshot of current page
  def take_screenshot(url)
    # Generate filename based on URL
    filename = generate_screenshot_filename(url)
    filepath = File.join(@screenshot_dir, filename)

    # Take screenshot
    @browser.screenshot(path: filepath, format: 'png', quality: 80)

    puts "📸 Screenshot saved: #{filepath}"
    filepath
  rescue StandardError => e
    puts "❌ Screenshot failed: #{e.message}"
    nil
  end

  # Analyze page structure and content
  def analyze_page_structure
    structure = @browser.evaluate(<<~JS)
      function analyzeStructure() {
        var analysis = {
          headings: [],
          forms: [],
          images: [],
          links: 0,
          interactive_elements: 0,
          content_sections: 0
        };
      #{'  '}
        // Analyze headings
        var headings = document.querySelectorAll('h1, h2, h3, h4, h5, h6');
        headings.forEach(function(h) {
          analysis.headings.push({
            level: h.tagName,
            text: h.innerText.substring(0, 100)
          });
        });
      #{'  '}
        // Analyze forms
        var forms = document.querySelectorAll('form');
        forms.forEach(function(form) {
          var inputs = form.querySelectorAll('input, select, textarea').length;
          analysis.forms.push({
            action: form.action || '',
            method: form.method || 'GET',
            inputs: inputs
          });
        });
      #{'  '}
        // Count elements
        analysis.images = document.querySelectorAll('img').length;
        analysis.links = document.querySelectorAll('a[href]').length;
        analysis.interactive_elements = document.querySelectorAll('button, input, select, textarea').length;
        analysis.content_sections = document.querySelectorAll('article, section, .content, .post').length;
      #{'  '}
        return analysis;
      }

      analyzeStructure();
    JS

    structure || {}
  end

  # Extract links from current page
  def extract_links(base_url)
    links = @browser.evaluate(<<~JS)
      var links = [];
      var anchors = document.querySelectorAll('a[href]');

      anchors.forEach(function(a) {
        var href = a.href;
        if (href && !href.startsWith('javascript:') && !href.startsWith('mailto:')) {
          links.push(href);
        }
      });

      return links;
    JS

    # Convert relative URLs to absolute
    (links || []).map do |link|
      resolve_url(base_url, link)
    end.compact.uniq
  end

  # Lovdata.no specific scraping enhancements
  def scrape_lovdata(url, options = {})
    options = { lovdata_specific: true }.merge(options)
    
    begin
      puts "🏛️ Scraping Lovdata.no: #{url}..."
      
      # Navigate with specific wait for Lovdata
      @browser.go_to(url)
      wait_for_lovdata_content
      
      # Extract Lovdata-specific content
      content = extract_lovdata_content
      
      # Take screenshot
      screenshot_path = take_screenshot(url)
      
      # Analyze Lovdata structure
      analysis = analyze_lovdata_structure
      
      # Extract related laws and regulations
      related_links = extract_lovdata_related_links(url) if options[:extract_links]
      
      result = {
        url: url,
        title: content[:title],
        law_reference: content[:law_reference],
        content: content[:text],
        html: content[:html],
        law_structure: content[:law_structure],
        section_hierarchy: content[:section_hierarchy],
        screenshot: screenshot_path,
        analysis: analysis,
        related_links: related_links,
        timestamp: Time.now,
        success: true,
        source: 'lovdata.no'
      }
      
      puts "✅ Successfully scraped Lovdata.no: #{url}"
      result
    rescue StandardError => e
      puts "❌ Lovdata scraping failed for #{url}: #{e.message}"
      { url: url, error: e.message, success: false, source: 'lovdata.no' }
    end
  end

  # Enhanced content extraction for Lovdata.no
  def extract_lovdata_content
    title = @browser.evaluate(<<~JS)
      var titleElement = document.querySelector('h1, .lovtittel, .title, .main-title');
      return titleElement ? titleElement.innerText : document.title;
    JS

    # Extract law reference number
    law_reference = @browser.evaluate(<<~JS)
      var refElement = document.querySelector('.lov-ref, .lovnummer, .law-number');
      if (refElement) return refElement.innerText;
      
      // Try to extract from URL or page content
      var content = document.body.innerText;
      var matches = content.match(/(?:LOV|FOR)\\s+\\d{4}-\\d{2}-\\d{2}-\\d+/);
      return matches ? matches[0] : null;
    JS

    # Extract structured law content
    law_content = @browser.evaluate(<<~JS)
      function extractLawStructure() {
        var structure = {
          chapters: [],
          sections: [],
          paragraphs: []
        };
        
        // Extract chapters (kapittel)
        var chapters = document.querySelectorAll('.kapittel, .chapter, h2');
        chapters.forEach(function(chapter, index) {
          structure.chapters.push({
            number: index + 1,
            title: chapter.innerText.trim(),
            id: chapter.id || 'chapter-' + (index + 1)
          });
        });
        
        // Extract sections (paragraf)
        var sections = document.querySelectorAll('.paragraf, .section, .lov-paragraf');
        sections.forEach(function(section) {
          var sectionNum = section.querySelector('.paragrafnummer, .section-number');
          var sectionText = section.querySelector('.paragroftekst, .section-text, p');
          
          structure.sections.push({
            number: sectionNum ? sectionNum.innerText : '',
            text: sectionText ? sectionText.innerText : section.innerText,
            id: section.id || ''
          });
        });
        
        return structure;
      }
      
      return extractLawStructure();
    JS

    # Extract main text content with legal structure preserved
    text_content = @browser.evaluate(<<~JS)
      // Remove navigation, ads, and non-content elements
      var elementsToRemove = document.querySelectorAll('nav, .nav, .ads, .advertisement, footer, .footer, .sidebar');
      elementsToRemove.forEach(function(el) { el.remove(); });
      
      // Get main content area for Lovdata
      var mainContent = document.querySelector('.lovtekst, .lov-innhold, .law-content, main, .content');
      if (mainContent) {
        return mainContent.innerText;
      }
      
      // Fallback to body content
      return document.body.innerText;
    JS

    # Get full HTML for detailed analysis
    html = @browser.evaluate('document.documentElement.outerHTML')

    {
      title: title&.strip || '',
      law_reference: law_reference&.strip,
      text: clean_text(text_content || ''),
      html: html,
      law_structure: law_content || {},
      section_hierarchy: extract_section_hierarchy(law_content)
    }
  end

  # Wait for Lovdata.no specific content to load
  def wait_for_lovdata_content(timeout = 15)
    @browser.evaluate_async(<<~JS, timeout)
      function waitForLovdata() {
        if (document.querySelector('.lovtekst, .lov-innhold, .law-content') || 
            document.readyState === 'complete') {
          arguments[0]();
        } else {
          setTimeout(waitForLovdata, 500);
        }
      }
      waitForLovdata();
    JS
  rescue Ferrum::TimeoutError
    puts '⚠️ Lovdata content load timeout'
  end

  # Analyze Lovdata.no page structure
  def analyze_lovdata_structure
    structure = @browser.evaluate(<<~JS)
      function analyzeLovdataStructure() {
        var analysis = {
          document_type: 'unknown',
          law_sections: 0,
          chapters: 0,
          references: [],
          amendments: [],
          effective_date: null
        };
        
        // Determine document type
        var url = window.location.href;
        if (url.includes('/lov/')) {
          analysis.document_type = 'law';
        } else if (url.includes('/forskrift/')) {
          analysis.document_type = 'regulation';
        } else if (url.includes('/rettskilder/')) {
          analysis.document_type = 'legal_source';
        }
        
        // Count structural elements
        analysis.law_sections = document.querySelectorAll('.paragraf, .section').length;
        analysis.chapters = document.querySelectorAll('.kapittel, .chapter').length;
        
        // Extract cross-references
        var refs = document.querySelectorAll('a[href*="lovdata.no"]');
        refs.forEach(function(ref) {
          analysis.references.push({
            text: ref.innerText,
            url: ref.href
          });
        });
        
        // Look for effective dates
        var dateElements = document.querySelectorAll('.ikrafttredelse, .effective-date');
        if (dateElements.length > 0) {
          analysis.effective_date = dateElements[0].innerText;
        }
        
        return analysis;
      }
      
      return analyzeLovdataStructure();
    JS

    structure || {}
  end

  # Extract related links specific to Lovdata.no
  def extract_lovdata_related_links(base_url)
    links = @browser.evaluate(<<~JS)
      var links = [];
      var anchors = document.querySelectorAll('a[href*="lovdata.no"]');
      
      anchors.forEach(function(a) {
        var href = a.href;
        if (href && !href.includes('#') && !href.includes('javascript:')) {
          links.push({
            url: href,
            text: a.innerText.trim(),
            type: href.includes('/lov/') ? 'law' : 
                  href.includes('/forskrift/') ? 'regulation' : 'other'
          });
        }
      });
      
      return links;
    JS

    (links || []).uniq { |link| link[:url] }
  end

  # Extract hierarchical structure from law content
  def extract_section_hierarchy(law_structure)
    return {} unless law_structure.is_a?(Hash)

    hierarchy = {
      root: law_structure[:chapters] || [],
      sections: {}
    }

    # Group sections by chapter
    if law_structure[:sections]
      law_structure[:sections].each do |section|
        chapter_id = determine_chapter_for_section(section, law_structure[:chapters])
        hierarchy[:sections][chapter_id] ||= []
        hierarchy[:sections][chapter_id] << section
      end
    end

    hierarchy
  end

  def determine_chapter_for_section(section, chapters)
    # Simple heuristic to associate sections with chapters
    return 'general' if chapters.nil? || chapters.empty?
    
    # For now, distribute sections evenly across chapters
    section_index = section[:number].to_i rescue 0
    chapter_index = [section_index / 10, chapters.size - 1].min
    
    chapters[chapter_index]&.dig(:id) || 'general'
  end

  # Close browser
  def close
    @browser&.quit
    puts '🔌 Browser closed'
  end

  private

  # Default configuration
  def default_config
    {
      screenshot_dir: 'data/screenshots',
      max_depth: 2,
      timeout: 30,
      user_agent: 'AI3-UniversalScraper/1.0',
      window_size: [1920, 1080],
      headless: true
    }
  end

  # Initialize Ferrum browser
  def initialize_browser
    options = {
      headless: @config[:headless],
      timeout: @config[:timeout],
      window_size: @config[:window_size],
      browser_options: {
        'user-agent' => @user_agent,
        'disable-gpu' => nil,
        'no-sandbox' => nil,
        'disable-dev-shm-usage' => nil
      }
    }

    @browser = Ferrum::Browser.new(**options)
    puts '🌐 Browser initialized'
  rescue StandardError => e
    puts "❌ Failed to initialize browser: #{e.message}"
    puts '💡 Make sure Chrome/Chromium is installed'
    raise
  end

  # Wait for page to load
  def wait_for_page_load(timeout = 10)
    @browser.evaluate_async(<<~JS, timeout)
      if (document.readyState === 'complete') {
        arguments[0]();
      } else {
        window.addEventListener('load', arguments[0]);
      }
    JS
  rescue Ferrum::TimeoutError
    puts '⚠️ Page load timeout'
  end

  # Validate URL format
  def valid_url?(url)
    uri = URI.parse(url)
    uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)
  rescue URI::InvalidURIError
    false
  end

  # Generate screenshot filename
  def generate_screenshot_filename(url)
    # Create a safe filename from URL
    safe_name = url.gsub(/[^a-zA-Z0-9]/, '_')
    hash = Digest::SHA256.hexdigest(url)[0..8]
    timestamp = Time.now.strftime('%Y%m%d_%H%M%S')

    "#{timestamp}_#{hash}_#{safe_name[0..50]}.png"
  end

  # Clean extracted text
  def clean_text(text)
    # Remove extra whitespace and normalize
    text.gsub(/\s+/, ' ')
        .gsub(/\n\s*\n/, "\n")
        .strip
  end

  # Calculate content complexity for cognitive load
  def calculate_content_complexity(content)
    return 1.0 unless content.is_a?(Hash)

    complexity = 0

    # Text length factor
    text_length = content[:text]&.length || 0
    complexity += (text_length / 1000.0).clamp(0, 3)

    # HTML complexity
    html = content[:html] || ''
    complexity += (html.scan(/<[^>]+>/).size / 100.0).clamp(0, 2)

    # Title complexity
    title = content[:title] || ''
    complexity += (title.split.size / 10.0).clamp(0, 1)

    complexity.clamp(1.0, 5.0)
  end

  # Resolve relative URLs
  def resolve_url(base_url, link)
    URI.join(base_url, link).to_s
  rescue URI::InvalidURIError
    nil
  end

  # Check if URLs are from same domain
  def same_domain?(url1, url2)
    URI.parse(url1).host == URI.parse(url2).host
  rescue URI::InvalidURIError
    false
  end
end
